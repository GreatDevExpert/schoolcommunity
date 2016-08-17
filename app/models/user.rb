class User < ActiveRecord::Base
  include Monitorable
  include Notifiable

  default_scope { where.not(state: 'suspended') }


  attr_accessor :existing_photo_id
  before_validation :copy_existing_file
  after_validation :update_age

  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
        :omniauthable, omniauth_providers: [:facebook]

  geocoded_by :postal_code
  after_validation :geocode, if: -> (obj) { obj.postal_code.present? and obj.postal_code_changed?} # => 

  reverse_geocoded_by :latitude, :longitude do |obj, results|
    if geo = results.first
      obj.postal_code = geo.postal_code if geo.postal_code
    end
  end
  after_validation :reverse_geocode, if: -> (obj) { obj.latitude.present? and obj.latitude_changed?}

  has_many :fellowships, dependent: :destroy
  has_many :schools, -> { where("fellowships.role IN ('student', 'alumni', 'faculty', 'parent') OR (fellowships.role = 'monitor' AND fellowships.status = 'approved') OR fellowships.role IS NULL").uniq }, through: :fellowships
  has_many :monitored_schools, -> { where(fellowships: {role: 'monitor', status: 'approved'})}, through: :fellowships, source: :school
  accepts_nested_attributes_for :fellowships

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :birthday, presence: true, on: :update
  validate :ensure_over_13, on: :update
  validates :city_description, presence: true, on: :update
  validates :postal_code, presence: true, on: :update
  validates_format_of :postal_code, :with => /\A\d{5}(-\d{4})?\z/, :message => "should be in the form 12345 or 12345-1234", on: :update

  has_many :friendships, dependent: :destroy
  has_many :faculty, -> (object) { where('fellowships.role = ?', 'faculty') }, through: :fellowships, source: :user, class_name: 'User'
  has_many :friends, through: :friendships

  # we have an unscoped options because we want to show suspended user activity on the current_users activity
  has_many :unscoped_friendships, dependent: :destroy, class_name: 'Friendship', unscoped: true
  has_many :unscoped_friends, -> {unscope(where: :state)}, through: :unscoped_friendships, source: :friend

  has_many :parent_relationships, class_name: 'ParentChildRelationship', foreign_key: 'child_id', dependent: :destroy 
  has_many :child_relationships, dependent: :destroy, class_name: 'ParentChildRelationship', foreign_key: 'parent_id'
  has_many :parents, -> { where(parent_child_relationships: {aasm_state: 'approved'})}, through: :parent_relationships
  has_many :children, -> { where(parent_child_relationships: {aasm_state: 'approved'})},through: :child_relationships
  has_many :friendship_recommendations, dependent: :destroy
  has_many :recommended_friends, through: :friendship_recommendations
  has_many :photos
  has_many :user_photos, -> (object) { where(group_id: nil).where(school_id: nil) }, source: :photo, class_name: 'Photo'
  has_many :school_photos, -> (object) { where.not(school_id: nil) }, source: :photo, class_name: 'Photo'
  has_many :group_photos, -> (object) { where.not(group_id: nil) }, source: :photo, class_name: 'Photo'
  has_many :documents
  has_many :user_documents, -> (object) { where(group_id: nil).where(school_id: nil) }, source: :document, class_name: 'Document'
  has_many :school_documents, -> (object) { where.not(school_id: nil) }, source: :document, class_name: 'Document'
  has_many :group_documents, -> (object) { where.not(group_id: nil) }, source: :document, class_name: 'Document'
  has_many :videos
  has_many :user_videos, -> (object) { where(group_id: nil).where(school_id: nil) }, source: :video, class_name: 'Video'
  has_many :school_videos, -> (object) { where.not(school_id: nil) }, source: :video, class_name: 'Video'
  has_many :group_videos, -> (object) { where.not(group_id: nil) }, source: :video, class_name: 'Video'
  has_many :comments
  has_many :suggestions
  has_many :posts
  has_many :battles_started, -> (object) { where.not(aasm_state: 'draft') }, foreign_key: 'owner_id', class_name: 'Battle'
  has_many :votes
  has_many :memberships, -> (object) { where('memberships.role IN (?)', ['standard', 'monitor']) }
  has_many :groups, -> { uniq }, through: :memberships
  has_many :monitored_groups, -> { where(memberships: {role: 'monitor', status: 'approved'})}, through: :memberships, source: :group
  has_many :rivalries
  has_many :rival_schools, -> (object) { where.not('schools.id' => nil) }, through: :rivalries, source: :school, class_name: 'School'
  has_many :rival_groups, -> (object) { where.not('groups.id' => nil) }, through: :rivalries, source: :group, class_name: 'Group'
  has_many :rival_people, -> (object) { where.not('id' => nil) }, through: :rivalries, class_name: 'User', source: :rival_user
  has_many :sent_friendship_requests, -> (object) { where "status = 'pending'"},
    class_name: 'FriendshipRequest'
  has_many :pending_friendship_requests, -> (object) { where "status = 'pending'"},
    class_name: 'FriendshipRequest', foreign_key: 'friend_id'
  has_many :flags_reported, class_name: 'Flag', foreign_key: :reporting_user_id
  has_many :flags_offenses, class_name: 'Flag', foreign_key: :offending_user_id
  has_many :confirmed_flags_offenses, -> { where(action_taken: 'hide_content') }, class_name: 'Flag', foreign_key: :offending_user_id
  has_many :flags_resolved, class_name: 'Flag', foreign_key: :resolving_user_id
  has_one :scrilla_balance, dependent: :destroy
  has_many :sent_scrilla_transfers, class_name: 'ScrillaTransfer', foreign_key: 'sender_id'
  has_many :received_scrilla_transfers, class_name: 'ScrillaTransfer', foreign_key: 'recipient_id'
  has_many :passes

  # activity feed
  include PublicActivity::Model

  # carrierwave
  mount_uploader :avatar, AvatarUploader

  FLAG_REASONS_ARRAY = [
    ['Profile Does Not Show Face' , 'no_face'],
    ['Spam' , 'spam'],
    ['Prohibited' , 'prohibited'],
    ['Nudity/Pornography' , 'nudity_pornography'],
    ['Profanity' , 'profanity'],
    ['Other' , 'other'],
  ]

  # sunspot - solr search
  searchable do
    text :full_name
    text :email
    text :schools do
      schools.map { |school| school.name }
    end
    text :groups do
      groups.publicly_visible.map { |group| group.name }
    end
    text :friends do
      friends.map { |person| person.full_name }
    end
    string :user_state do
      state
    end

    string :publicly_searchable do
      if visibility !=  'visible'
        'false'
      elsif state != 'active'
        'false'
      else
        'true'
      end
    end
    integer :friend_count, stored: true
    integer :group_count, stored: true
    integer :school_count, stored: true
    integer :pass_count, stored: true
    time :current_sign_in_at
    text :class_nouns do
      'user person people'
    end
    string :class_facet do
      'people'
    end
    integer :participation_level do
      friend_count.to_i + group_count.to_i + school_count.to_i + (pass_count.to_i / 10)
    end
  end

  def self.from_omniauth(auth)
    account = unscoped.where(provider: auth["provider"], uid: auth["uid"]).first_or_create do |user|
      facebook_token = auth.credentials.token
      fb_graph = FacebookGraph.new(facebook_token)
      fb_graph.build_account(user)
      user.remote_avatar_url = fb_graph.get_avatar_url(auth.uid)
      user.state = 'confirm_profile'
    end
  end

  def active?
    state == 'active'
  end

  def not_active?
    state != 'active'
  end

  def suspended?
    state == 'suspended'
  end

  def friend_count
    friends.size
  end

  def group_count
    groups.size
  end

  def mailboxer_email(object)
    self.email
  end

  def school_count
    schools.count
  end

  def first_name_possessive
    first_name + ('s' == first_name[-1] ? "'" : "'"+"s")
  end

  def full_name_possessive
    first_name + " #{last_name + ('s' == last_name[-1] ? "'" : "'"+"s")}"
  end

  def update_age
    return if birthday.nil?
    # http://stackoverflow.com/questions/819263/get-persons-age-in-ruby
    now = Time.now.utc.to_date
    self.age = now.year - birthday.year - ((now.month > birthday.month || (now.month == birthday.month && now.day >= birthday.day)) ? 0 : 1)
  end

  # override devise method so only active users can access the site
  def active_for_authentication?
    false
    super && !self.active?
  end

  def full_name
    "#{first_name} #{last_name}"
  end
  alias_method :name, :full_name

  def to_param
    [id, full_name.parameterize].join("-")
  end

  # this method is called by devise, ensures banned users are not allowed to perform any more actions
  def active_for_authentication?
    inactive_states = %w(canceled suspended)
    super && !inactive_states.include?(self.state)
  end

  def inactive_message
    "Sorry, this account has been #{state}. Please contact support@myschool411.com to reactive your account."
  end

  def friend?(user)
    friends.pluck(:id).include?(user.id)
  end

  def not_friend?(user)
    friend?(user) == false
  end

  def pending_friendship_request?(user)
    pending_friendship_requests.pluck(:user_id).include?(user.id) ||
      sent_friendship_requests.pluck(:friend_id).include?(user.id)
  end

  def already_associated_with?(school)
    schools.pluck(:id).include?(school.id)
  end

  def already_associated_with_group?(group)
    groups.pluck(:id).include?(group.id)
  end

  def already_purchased_battle_pass?(battle)
    battle.passes.pluck(:user_id).include?(id)
  end

  def already_purchased_challenger_battle_pass?(battle)
    battle.challenger_passes.pluck(:user_id).include?(id)
  end

  def already_purchased_opponent_battle_pass?(battle)
    battle.opponent_passes.pluck(:user_id).include?(id)
  end

  def already_rival_schools?(school)
    rival_schools.pluck(:id).include?(school.id)
  end

  def already_rival_groups?(group)
    rival_groups.pluck(:id).include?(group.id)
  end

  def already_rival_people?(user)
    rival_people.pluck(:id).include?(user.id)
  end

  def is_a_group_member_of?(group)
    groups.pluck(:id).include?(group.id)
  end

  def minor?
    birthday >= 18.years.ago
  end

  def is_adult?
    minor? == false
  end

  def is_under_13?
    return false if birthday.nil?
    birthday >= 13.years.ago
  end

  def super_admin?
    has_role? :super_admin
  end

  def standard_user?
    super_admin? == false
  end

  def self.super_admins
    User.with_role(:super_admin)
  end

  def ensure_over_13
    errors.add(:birthday, "must be at least 13 years old.") if is_under_13?
  end
  
  def has_pending_monitor_request_for(school)
    school.monitor_requests.pluck(:user_id).include?(id)
  end

  def scrilla_transfers
    ScrillaTransfer.where(["sender_id = ? OR recipient_id = ?", id, id])
  end

  def voted_on?(battle)
    battle.votes.collect(&:user_id).include?(self.id)
  end

  def has_not_voted_on?(battle)
    voted_on?(battle) == false
  end

  def voted_on_first_item?(battle)
    battle.first_item_votes.collect(&:user_id).include?(self.id)
  end

  def voted_on_second_item?(battle)
    battle.second_item_votes.collect(&:user_id).include?(self.id)
  end

  def full_address
    "#{city_description} #{state} #{postal_code}"
  end

  def initialize_scrilla_balance
    unless scrilla_balance
      scrilla_balance = ScrillaBalance.create!(user: self, balance: 0)
      initial_transfer = ScrillaTransfer.create!(recipient: self,
        amount: ScrillaBalance::DEFAULT_STARTING_BALANCE,
        transfer_type: 'initial_deposit')
      initial_transfer.complete!
    end
  end

  def notification_users
    [self]
  end

  def is_a_monitor?
    fellowships.where(role: 'monitor', status: 'approved').present? || memberships.where(role: 'monitor', status: 'approved').present?
  end

  def public_monitored_groups_and_schools
    names = []
    monitored_schools = fellowships.where(role: 'monitor', status: 'approved').select{ |f| f.school.present? }.collect(&:school)
    monitored_groups = memberships.where(role: 'monitor', status: 'approved').select{ |m| (m.group.present? && m.group.visibility_type != 'private') }.collect(&:group)

    (monitored_schools + monitored_groups).uniq
  end

  def names_of_public_monitored_groups_and_schools
    names= public_monitored_groups_and_schools.collect(&:name)
    if names.size == 1
      names = names.first
    else 
      names = [names[0...-1].join(", "), names.last].join(" & ")
    end
    names
  end

  def fellowship_for_school(school = nil)
    return nil unless school
    fellowship = fellowships.where(school: school).where.not(role: 'monitor').first
    return nil unless fellowship
    fellowship.role
  end

  def monitor_of?(school_or_group)
    if school_or_group.kind_of?(Group)
      Membership.where(group: school_or_group, user: self, role: 'monitor', status: 'approved').exists?
    elsif school_or_group.kind_of?(School)
      Fellowship.where(school: school_or_group, user: self, role: 'monitor', status: 'approved').exists?
    else
      false
    end
  end

  def copy_existing_file
    if @existing_photo_id.present?
      existing_photo = Photo.find(@existing_photo_id)
      self.avatar = existing_photo.file
      @existing_photo_id = nil
    end
  end

  # class name is RailsSettings::SettingObject
  has_settings do |s|
    s.key :settings, defaults: {
      email_on_new_notification: true,
      share_activity_on_facebook: true,
    }
  end

end
