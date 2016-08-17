class Group < ActiveRecord::Base
  include Monitorable
  include Identifiable
  mount_uploader :avatar, AvatarUploader
  attr_accessor :existing_photo_id
  include PublicActivity::Model

  after_save :reindex_school #so member_count and is updated
  before_destroy :reindex_school #so member_count and is updated

  belongs_to :school
  has_many :photos
  has_many :documents
  has_many :videos
  has_many :memberships
  has_many :users, -> (object) { where('memberships.status = ?', 'approved').uniq }, through: :memberships
  has_many :posts

  before_validation :copy_existing_file

  validates :name, presence: true
  validates :name, :uniqueness => { :scope => :school_id }, unless: Proc.new { |g| g.school_id.blank? }
  validates :visibility_type, presence: true
  has_many :flagged_items, -> (object) { where(action_taken: 'open') }, as: :monitorable, class_name: 'Flag'

  has_many :monitors, -> (object) { where('memberships.role = ?', 'monitor').where('memberships.status = ?', 'approved') }, through: :memberships, source: :user, class_name: 'User'
  has_many :members, -> (object) { uniq.where('memberships.role IN (?)', ['standard', 'monitor']).where('memberships.status = ?', 'approved') }, through: :memberships, source: :user, class_name: 'User'
  has_many :membership_requests, -> (object) { where("memberships.role = 'awaiting_approval'") }, through: :memberships, source: :user, class_name: 'User'
  has_many :invited, -> (object) { where("memberships.role = 'invited'") }, through: :memberships, source: :user, class_name: 'User'
  has_many :monitor_requests, -> (object) { where('role = ?', 'monitor').where('status = ?', 'pending') }, source: :memberships, class_name: 'Membership'
  scope :publicly_visible, -> { where(visibility_type: 'public') }


  VISIBILITY_TYPES = [
    ['Public (open for all to join, visible to non-members)', 'public'],
    ['Moderated (must be approved, visible to non-members)', 'moderated'],
    ['Private (must be invited, not visible to non-members)', 'private']
  ]
  
  # sunspot - solr search
  searchable do
    text :name
    text :members do
      members.map { |user| user.full_name }
    end
    text :school_name do
      school.name unless school.blank?
    end
    integer :member_count, stored: true
    text :class_nouns do
      'group'
    end
    string :class_facet do
      'Groups'
    end
    string :publicly_searchable do
      (visibility_type != 'private').to_s
    end
    integer :participation_level do
      member_count.to_i
    end
  end

  def to_param
    [id, name.parameterize].join("-")
  end

  def has_pending_monitor_requests
    monitor_requests.size > 0
  end

  def full_name
    name
  end

  def member_count
    members.size
  end

  def battles
    # TODO seems like this should go in the has_many section of this model
    Battle.where('((opponent_type = ? AND opponent_id = ?) OR (challenger_type = ? AND challenger_id = ?))', 'Group', self.id, 'Group', self.id)
  end

  def join_group(user)
    case visibility_type
    when "public"
      membership = Membership.create(group: self, user: user, role: 'standard', status: 'approved')
      self.create_activity key: 'group.new_member', owner: user, recipient: self
    when "moderated"
      membership = Membership.create(group: self, user: user, role: 'awaiting_approval', status: 'awaiting_approval')
    when "private"
      membership = Membership.create(group: self, user: user, role: 'standard', status: 'approved')
      self.create_activity key: 'group.new_member', owner: user, recipient: self
    else
      raise "Visibility type #{visibility_type} not implemented"
    end
    
    # Remove any pending invitations
    Membership.where(user: user, group: self, role: 'invited').destroy_all

    membership
  end

  def add_invited_user(user)
    unless Membership.find_by(user: user, group: self)
      Membership.create(role: 'invited', user: user, group: self)
    end
  end

  def user_awaiting_approval?(user)
    Membership.exists?(user: user, group: self, role: 'awaiting_approval')
  end

  def user_invited?(user)
    Membership.exists?(user: user, group: self, role: 'invited')
  end

  def user_is_monitor?(user)
    Membership.exists?(user: user, group: self, role: 'monitor', status: 'approved')
  end

  def copy_existing_file
    if @existing_photo_id.present?
      existing_photo = Photo.find(@existing_photo_id)
      self.avatar = existing_photo.file
      @existing_photo_id = nil
    end
  end

  private

    def reindex_school
      # it's possible a user will change the school_id from an integer to nil. We need to reindex the old school to update the count
      return if school_id_change.nil?
      school_id_change.each do |id|
        return if id.nil?
        school = School.find(id)
        Reindex.perform_later(school)
      end
    end

end
