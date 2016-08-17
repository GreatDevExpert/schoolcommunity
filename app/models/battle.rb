class Battle < ActiveRecord::Base
  include Monitorable

  # activity feed
  include PublicActivity::Model
  # tracked owner: -> (controller, model) { controller && controller.current_user }, only: [:started]

  belongs_to :first_item, -> { unscope(where: :visibility) }, polymorphic: true
  belongs_to :opponent, -> { unscope(where: :visibility) }, polymorphic: true
  belongs_to :challenger, -> { unscope(where: :visibility) }, polymorphic: true
  belongs_to :second_item, -> { unscope(where: :visibility) }, polymorphic: true
  has_many :comments, as: :commentable, dependent: :destroy
  belongs_to :owner, class_name: 'User', unscoped: true
  belongs_to :opposing_user, foreign_key: :opposing_user_id,class_name: 'User', unscoped: true
  has_many :votes
  has_many :first_item_votes, -> (object) { where(item: 'first') }, class_name: 'Vote'
  has_many :second_item_votes, -> (object) { where(item: 'second') }, class_name: 'Vote'
  has_many :passes
  has_many :challenger_passes, -> (object) { where(kind: 'challenger') }, class_name: 'Pass'
  has_many :opponent_passes, -> (object) { where(kind: 'opponent') }, class_name: 'Pass'

  #scopes
  scope :currently_active, -> { where(aasm_state: ['open_for_voting', 'gametime', 'pregame', 'needs_scores']).order('created_at DESC') }
  scope :currently_closed, -> { where(aasm_state: ['closed']).order('created_at DESC') }
  scope :stale_drafts, lambda { where(["aasm_state = ? and updated_at < ?", "draft", Time.current - 2.weeks]) }

  # most validation happen in the form objects
  validates :ends_at, presence: true, if: Proc.new { |b| b.aasm_state == 'closed' }

  include AASM
  aasm :column => :aasm_state do
    state :draft, :initial => true
    state :open_for_voting
    state :challenge_pending
    state :closed
    state :pregame
    state :gametime
    state :needs_scores

    event :open_for_voting, after: -> { create_new_this_vs_that_battle_items } do
      transitions :from => :draft, :to => :open_for_voting
    end

    event :challenge_accepted, after: -> { create_challenge_accepted_items } do
      transitions :from => :challenge_pending, :to => :open_for_voting
    end

    event :close_voting, after: -> { create_battle_closed_items } do
      transitions :from => :open_for_voting, :to => :closed
    end

    event :challenge_opponent, after: -> { send_challenge } do
      transitions :from => :draft, :to => :challenge_pending
    end

    event :start_pregame, after: -> { create_school_vs_school_items } do
      transitions :from => :draft, :to => :pregame
    end

    event :start_game, after: -> { create_game_started_items } do
      transitions :from => :pregame, :to => :gametime
    end

    event :waiting_for_scores, after: -> { create_needs_scores_items } do
      transitions :from => :gametime, :to => :needs_scores
    end

    event :post_game, after: -> { create_school_vs_school_closed_items } do
      transitions :from => :needs_scores, :to => :closed
    end

  end

  # sunspot - solr search
  searchable do
    integer :owner_id
    integer :opposing_user_id
    text :name
    text :second_item_name
    text :first_item_name
    string :aasm_state
    text :description
    text :owner_user_name do
      owner.name unless owner.blank?
    end
    text :opponent_user_name do
      opposing_user.name unless opposing_user.blank?
    end
    text :opponent_name do
      opponent.name unless opponent.blank?
    end
    text :challenger_name do
      challenger.name unless challenger.blank?
    end
    text :sport_name
    text :sport_category
    text :collaborating_user_names do
      votes.pluck(:user_id).collect { |user_id| User.unscoped.find(user_id).name }
      comments.pluck(:user_id).collect { |user_id| User.unscoped.find(user_id).name }
    end
    text :class_nouns do
      'battle ' + human_battle_kind
    end
    string :class_facet do
      'Battle'
    end
    string :publicly_searchable do
      if aasm_state == 'draft'
        'false'
      elsif visibility != 'visible'
        'false'
      else
        'true'
      end
    end

    integer :comment_count
    integer :pass_count

    integer :participation_level do
      comment_count.to_i + first_item_vote_count.to_i.to_i + second_item_vote_count.to_i.to_i + (pass_count.to_i / 100)
    end
  end

  SPORT_CATEGORIES = [
    ['Mens', 'mens'],
    ['Womens', 'womens'],
    ['Co-Ed', 'co_ed'],
  ]

  WINNER_OPTIONS = [
    ['challenger', 'challenger'],
    # ['draw', 'draw'],
    ['opponent', 'opponent'],
  ]

  LENGTH_OPTIONS = [
    ['30 Minutes', '30_minutes'],
    ['1 Hour', '1_hour'],
    ['2 Hours', '2_hours'],
    ['4 Hours', '4_hours'],
    ['6 Hours', '6_hours'],
    ['12 Hours', '12_hours'],
    ['1 Day', '1_day'],
    ['2 Days', '2_days'],
    ['3 Days', '3_days'],
    ['5 Days', '5_days'],
  ]

  def name
    # intentionally nil, was using description, but battles were coming up really hight in the search results.
  end

  def user
    owner
  end

  def to_param
    if draft? || challenge_pending?
      super # when a aasm_state is 'draft' the items below can be nil
    else
      [id, description.to_s.parameterize, first_item_name.to_s.parameterize, 'or', second_item_name.to_s.parameterize].join("-")
    end
  end

  def comment_count
    comments.size
  end

  def human_battle_kind
    kind.titleize
  end

  def winner
    return unless closed?
    if kind == 'school_vs_school'
      # the user specifies the winner
      if game_winner_kind == 'challenger'
        challenger
      elsif game_winner_kind == 'opponent'
        opponent
      elsif game_winner_kind == 'draw'
        'draw'
      end
    elsif kind == 'group_vs_group'
      # we need to grab the group
      if first_item_vote_count.to_i > second_item_vote_count.to_i
        challenger
      elsif first_item_vote_count.to_i < second_item_vote_count.to_i
        opponent
      elsif first_item_vote_count.to_i == second_item_vote_count.to_i
        'draw'
      end
    elsif kind == 'me_vs_you'
      # we need to grab the user who uploaded the item
      if first_item_vote_count.to_i > second_item_vote_count.to_i
        owner
      elsif first_item_vote_count.to_i < second_item_vote_count.to_i
        opposing_user
      elsif first_item_vote_count.to_i == second_item_vote_count.to_i
        'draw'
      end
    else
      if first_item_vote_count.to_i > second_item_vote_count.to_i
        first_item
      elsif first_item_vote_count.to_i < second_item_vote_count.to_i
        second_item
      elsif first_item_vote_count.to_i == second_item_vote_count.to_i
        'draw'
      end
    end
  end

  def loser
    return unless closed?
    if kind == 'school_vs_school'
      # the user specifies the winer, so we deduce the loser
      if game_winner_kind == 'challenger'
        opponent
      elsif game_winner_kind == 'opponent'
        challenger
      elsif game_winner_kind == 'draw'
        'draw'
      end
    elsif kind == 'group_vs_group'
      # we need to grab the group
      if first_item_vote_count.to_i < second_item_vote_count.to_i
        challenger
      elsif first_item_vote_count.to_i > second_item_vote_count.to_i
        opponent
      elsif first_item_vote_count.to_i == second_item_vote_count.to_i
        'draw'
      end
    elsif kind == 'me_vs_you'
      # we need to grab the user who uploaded the item
      if first_item_vote_count.to_i < second_item_vote_count.to_i
        owner
      elsif first_item_vote_count.to_i > second_item_vote_count.to_i
        opposing_user
      elsif first_item_vote_count.to_i == second_item_vote_count.to_i
        'draw'
      end
    else
      if first_item_vote_count.to_i < second_item_vote_count.to_i
        first_item
      elsif first_item_vote_count.to_i > second_item_vote_count.to_i
        second_item
      elsif first_item_vote_count.to_i == second_item_vote_count.to_i
        'draw'
      end
    end
  end

  def set_end_time(option)
    # 1_hour should give use 1.hour
    number_and_period = option.split('_')
    number = number_and_period[0].to_i
    period = number_and_period[1]
    self.ends_at = Time.current + number.send(period)
  end

  def create_challenge_accepted_items
    uuid = SecureRandom.uuid

    if kind == 'group_vs_group'
      self.create_activity action: "group_vs_group_started", owner: nil, recipient: opponent, uuid: uuid
      self.create_activity action: "group_vs_group_started", owner: nil, recipient: challenger, uuid: uuid
    elsif kind == 'me_vs_you'
      self.create_activity action: "me_vs_you_accepted", owner: opposing_user, uuid: uuid
      self.create_activity action: "me_vs_you_started", owner: owner, uuid: uuid
      # BattleMailer.challenge_accepted(self).deliver_later
    end
    Battles::CloseVoting.set(wait_until: ends_at).perform_later(self)
    send_challenge_accepted_notifications
  end

  def create_new_this_vs_that_battle_items
    new_battle_purchase(50)
    self.create_activity action: 'this_vs_that_started', owner: owner
    send_new_this_vs_that_battle_notifications
    Battles::CloseVoting.set(wait_until: ends_at).perform_later(self)
  end

  def create_battle_closed_items
    uuid = SecureRandom.uuid

    send_battle_closed_notifications
    if kind == 'this_vs_that'
      self.create_activity action: "this_vs_that_battle_finished", owner: owner, uuid: uuid
    elsif kind == 'me_vs_you'
      if winner == loser # it's a draw
        self.create_activity action: "#{kind}_draw", owner: owner, uuid: uuid
        self.create_activity action: "#{kind}_draw", owner: opposing_user, uuid: uuid
      else
        self.create_activity action: "#{kind}_winner", owner: winner, uuid: uuid
        self.create_activity action: "#{kind}_winner", owner: loser, uuid: uuid
      end
    else
      if winner == loser # its' a draw
        self.create_activity action: "#{kind}_draw", owner: nil, recipient: challenger, uuid: uuid
        self.create_activity action: "#{kind}_draw", owner: nil, recipient: opponent, uuid: uuid
      else
        # send same activity to both sides
        self.create_activity action: "#{kind}_winner", owner: nil, recipient: winner, uuid: uuid
        self.create_activity action: "#{kind}_winner", owner: nil, recipient: loser, uuid: uuid
      end
    end
  end

  def create_school_vs_school_items
    # using a uuid to make sure the activity only shows onces per users if they are a member of both the challenger and opponent
    uuid = SecureRandom.uuid

    # they get a free 50 scrill pass when starting a school vs school battle
    Pass.create(amount: 50, kind: 'challenger', user: owner, battle: self)
    Battles::StartGame.set(wait_until: game_time).perform_later(id)
    self.create_activity action: 'school_vs_school_started', owner: owner, recipient: challenger, role: 'everyone', uuid: uuid
    self.create_activity action: 'school_vs_school_started', owner: owner, recipient: opponent, role: 'everyone', uuid: uuid

    # send users of the opponent school another type of notification
    opponent.users.each do |school_opponent_user|
      unless school_opponent_user == owner
        BattleSchoolChallengedNotification.new(battle: self, recipient: school_opponent_user, notifier: self).notify
      end
    end

    # send users of the challenger school on type of notification
    
    # a user could be a member of both sides
    # we don't want to send a notification two times to the same user
    do_not_send_to_these_users_ids = (opponent.users.pluck(:id) << owner.id)

    challenger.users.each do |school_challenger_user|
      unless do_not_send_to_these_users_ids.include?(school_challenger_user.id)
        BattleNotification.new(battle: self, recipient: school_challenger_user, notifier: self).notify
      end
    end
  end

  def create_game_started_items
    Battles::EndSchoolVsSchool.set(wait_until: ends_at).perform_later(id)
  end

  def create_school_vs_school_closed_items
    uuid = SecureRandom.uuid

    if winner == loser
      self.create_activity action: "school_vs_school_draw", owner: nil, recipient: challenger, role: 'everyone', uuid: uuid
      self.create_activity action: "school_vs_school_draw", owner: nil, recipient: opponent, role: 'everyone', uuid: uuid
    else
      self.create_activity action: "school_vs_school_winner", owner: nil, recipient: winner, role: 'everyone', uuid: uuid
      self.create_activity action: "school_vs_school_winner", owner: nil, recipient: loser, role: 'everyone', uuid: uuid
    end
    # set job to award the winners (delayed so admin can change stuff)
    Battles::AwardWinners.set(wait: 12.hours).perform_later(self)
  end

  def create_needs_scores_items
    # check in an hour and start nagging via email
    Battles::CheckScores.set(wait: 1.hour).perform_later(id)
  end

  def send_challenge
    new_battle_purchase(50)
    if kind == 'me_vs_you'
      self.create_activity action: 'you_have_been_challenged', owner: nil, recipient: opposing_user
      send_me_vs_you_challenge_notification
      # BattleMailer.new_challenge(self).deliver_later
    elsif kind == 'group_vs_group'
      self.create_activity action: 'your_group_has_been_challenged', owner: nil, recipient: opponent
      # owner above is nil so the activity does not show up for friends of the person
      # person who are not members of the group and therefore can not accept
      # the challenge
      send_group_vs_group_challenge_notification
    end
  end

  def sport_icon
    SPORT_OPTIONS.select { |array| array[0] == sport_name }.uniq.flatten[2]
  end

  def challenger_battle_pass_total
    challenger_passes.pluck(:amount).inject(:+)
  end

  def opponent_battle_pass_total
    opponent_passes.pluck(:amount).inject(:+)
  end

  def challenger_spirit_percentage
    # minus 1 so the bar graph always shows two colors
    ((challenger_battle_pass_total.to_f / passes.pluck(:amount).inject(:+).to_f) * 100) - 1
  end

  def challenger_vote_percentage
    return 50 if first_item_vote_count.blank? && second_item_vote_count.blank?
    return 1 if first_item_vote_count.blank?
    # minus 1 so the bar graph always shows two colors
    (first_item_vote_count.to_f / (first_item_vote_count.to_f + second_item_vote_count.to_f) * 100)-1
  end

  def payout_winners
    if game_winner_kind == 'draw'
      # user gets their money back
      passes.each do |pass|
        ScrillaTransfer.create(recipient: pass.user, amount: pass.amount, transfer_type: 'battle_payout_draw').complete!
          AwardWinnersNotification.new(battle: self, recipient: pass.user, notifier: self).notify
      end
    elsif game_winner_kind == 'challenger'
      # payout those who supported the challenger
      challenger_passes.each do |pass|
        payout_amount = pass.amount * 2
        ScrillaTransfer.create(recipient: pass.user, amount: payout_amount, transfer_type: 'battle_payout_winner').complete!
        AwardWinnersNotification.new(battle: self, recipient: pass.user, notifier: self).notify
      end
    elsif game_winner_kind == 'opponent'
      # payout those who supported the opponent
      opponent_passes.each do |pass|
        payout_amount = pass.amount * 2
        ScrillaTransfer.create(recipient: pass.user, amount: payout_amount, transfer_type: 'battle_payout_winner').complete!
        AwardWinnersNotification.new(battle: self, recipient: pass.user, notifier: self).notify
      end
    end
  end

  def notification_users
    [owner]
  end

  def set_game_time
    # reformatting start_date due to the the way rails wants time formats and the way we want to show them on the datepicker, using a string
    date_array = start_date.to_s.split('/')
    new_order = [2, 0, 1]
    reformated_start_date_string = (date_array.values_at *new_order).join('/')
    self.game_time = Time.zone.parse("#{reformated_start_date_string} #{start_time}")
  end

  private

  def new_battle_purchase(amount)  
    transfer = ScrillaTransfer.create(sender: owner, amount: amount, transfer_type: 'battle_purchase')
    raise "Invalid transfer" unless transfer.valid?
    transfer.complete
  end

  def send_new_this_vs_that_battle_notifications
    return if owner.friends.blank?
    owner.friends.each do |friend|
      BattleNotification.new(battle: self, recipient: friend).notify
    end
  end

  def send_me_vs_you_challenge_notification
    BattleChallengeNotification.new(battle: self, recipient: opposing_user).notify
  end

  def send_group_vs_group_challenge_notification
    opponent.members.each do |group_member|
      unless group_member == owner
        BattleChallengeNotification.new(battle: self, recipient: group_member).notify
      end
    end
  end

  def send_challenge_accepted_notifications
    BattleChallengeAcceptedNotification.new(battle: self, recipient: owner).notify
    if kind == 'me_vs_you'
      friends_of_both_sides = (owner.friends + opposing_user.friends).uniq
      friends_of_both_sides.each do |friend|
        unless friend == owner || friend == opposing_user
          BattleNotification.new(battle: self, recipient: friend).notify
        end
      end
    elsif kind == 'group_vs_group'
      members_of_both_sides = (challenger.members + opponent.members).uniq
      members_of_both_sides.each do |group_member|
        unless group_member == owner || group_member == opposing_user
          BattleNotification.new(battle: self, recipient: group_member).notify
        end
      end
    end
  end

  def send_battle_closed_notifications
    if kind == 'school_vs_school'
      # send notification to all users with battle passes
      passes.each do |pass|
        BattleClosedNotification.new(battle: self, recipient: pass.user).notify
      end
    else
      # send notification to all voters
      votes.each do |vote|
        unless vote.user == owner
          BattleClosedNotification.new(battle: self, recipient: vote.user).notify
        end
      end
      # in a this vs that battle the owner does not have to vote from the owner
      # but we still want to send it
      BattleClosedNotification.new(battle: self, recipient: owner).notify
    end
  end

end
