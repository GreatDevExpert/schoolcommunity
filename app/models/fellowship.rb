class Fellowship < ActiveRecord::Base
  include Monitorable
  include Identifiable
  
  after_commit :reindex_school #so user_count is updated
  after_validation :truncate_graduation_date
  after_create :send_faculty_notifications
  before_create :establish_parent_fellowships
  before_destroy :remove_parent_fellowships
  before_save :update_parent_graduation_dates
  before_destroy :remove_related_notifications
  belongs_to :user, unscoped: true
  belongs_to :school
  validates :role, presence: true, if: :user_state_present?
  validates :status, presence: true, if: :user_state_present?
  validates :graduation_date, presence: true, if: :graduation_date_required?
  has_many :comments, as: :commentable, dependent: :destroy
  validate :user, :minors_can_only_be_member_of_single_school, if: :user_state_present?

  validates_uniqueness_of :user, :scope => [:role, :school], unless: :parent?, :message => "Relationship has already been established"

  FACULTY_NOTIFICATIONS_TO_SEND = 5

  # activity feed
  include PublicActivity::Model

  STANDARD_ROLES = [
    ['Student', 'student'],
    ['Parent', 'parent'],
    ['Alumni', 'alumni'],
    ['Faculty', 'faculty']
  ]

  JOIN_ROLES = [
    ['Student', 'student'],
    ['Alumni', 'alumni'],
  ]

  searchable do
    text :full_name do
      user.full_name unless user.blank?
    end
    string :role_name do
      role
    end
    integer :school_id
    text :graduation_year
    string :graduation_year

    string :publicly_searchable do
      if user.blank?
        'false'
      else
        'true'
      end
    end
  end

  def notification_users
    [user]
  end

  def long_graduation_year
    if graduation_year && (role == 'student' || role == 'alumni')
      "Class of #{graduation_year}"
    end
  end

  def graduation_year
    return nil unless graduation_date
    graduation_date.year
  end

  def earliest_valid_graduation_year
    if role == 'student'
      Date.today.year
    elsif role == 'alumni'
      Date.today.year - 100
    end
  end

  def latest_valid_graduation_year
    if role == 'student'
      Date.today.year + 8
    elsif role == 'alumni'
      Date.today.year
    end
  end

  def role_with_year
    if role == 'student' || role == 'alumni' || role == 'parent'
      "#{role} #{graduation_year}"
    else
      role
    end
  end

  def become_alumni!
    raise "Only students can become alumni" unless role == 'student'
    remove_parent_fellowships
    update(role: 'alumni')
  end

  def parent?
    role == 'parent'
  end

  def send_faculty_notifications
    if role == 'faculty'
      # we need to remove the just joined faculty member from the list of faculty members
      existing_faculty_members = school.faculty.where.not(fellowships: {user: user})

      if existing_faculty_members.count == 0
        User.super_admins.each do |admin_user|
          FacultyJoinNotification.new(recipient: admin_user, requestor: user, notifier: self).notify
        end
      else 
        faculty_members = existing_faculty_members.order('RANDOM()').limit(FACULTY_NOTIFICATIONS_TO_SEND)
        faculty_members.each do |faculty_member|
          FacultyJoinNotification.new(recipient: faculty_member, requestor: user, notifier: self).notify
        end
      end
    end
  end

  private

    def user_state_present?
      # We want to allow the user to select their role at each school on the first step of signin up
      return false if user.nil?
      user.state.present?
    end

    def reindex_school
      Reindex.perform_later(user)
      Reindex.perform_later(school)
    end

    def truncate_graduation_date
      if self.graduation_date?
        self.graduation_date = self.graduation_date.beginning_of_year
      end
    end

    def graduation_date_required?
      role == 'student' || role == 'alumni'
    end

    def minors_can_only_be_member_of_single_school
      if user.minor? && user.schools.count > 0
        errors.add(:user, "minors can only be member of a single school")
      end
    end

    def establish_parent_fellowships
      if role == 'student' && user.parents.count > 0
        user.parents.each do |parent|
          Fellowship.create(user: parent, school: school, role: 'parent', status: 'approved', graduation_date: graduation_date)
        end
      end
    end

    def remove_parent_fellowships
      if role == 'student' && user.parents.count > 0
        user.parents.each do |parent|
          fellowship = parent.fellowships.find_by(school: school, graduation_date: graduation_date, role: 'parent')
          fellowship.destroy! if fellowship
        end
      end
    end

    def remove_related_notifications
      Notification.where(notifier: self).destroy_all
    end

    def update_parent_graduation_dates
      if role == 'student' && user.parents.count > 0 && graduation_date_changed?
        user.parents.each do |parent|
          fellowship = parent.fellowships.find_by(school: school, graduation_date: graduation_date_was, role: 'parent')
          fellowship.update(graduation_date: graduation_date) if fellowship
        end
      end
    end

    def name
      if school
        "#{school.name} (#{role.capitalize})"
      else
        ""
      end
    end
end
