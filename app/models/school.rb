class School < ActiveRecord::Base
  include Monitorable
  include Identifiable

  include PublicActivity::Model

  # carrierwave
  mount_uploader :avatar, AvatarUploader

  has_many :groups
  has_many :visible_groups, -> (object) { where.not(visibility_type: 'private')}, class_name: 'Group'
  has_many :documents
  has_many :fellowships, dependent: :destroy
  has_many :users, -> { uniq }, through: :fellowships
  has_many :students, -> (object) { where('fellowships.role = ?', 'student') }, through: :fellowships, source: :user, class_name: 'User'
  has_many :alumnus, -> (object) { where('fellowships.role = ?', 'alumni') }, through: :fellowships, source: :user, class_name: 'User'
  has_many :parents, -> (object) { where('fellowships.role = ?', 'parent') }, through: :fellowships, source: :user, class_name: 'User'
  has_many :faculty, -> (object) { where('fellowships.role = ?', 'faculty') }, through: :fellowships, source: :user, class_name: 'User'
  
  has_many :monitors, -> (object) { where('fellowships.role = ?', 'monitor').where('fellowships.status = ?', 'approved') }, through: :fellowships, source: :user, class_name: 'User'
  has_many :posts
  has_many :monitor_requests, -> (object) { where('role = ?', 'monitor').where('status = ?', 'pending') }, source: :fellowships, class_name: 'Fellowship'

  has_many :comments, as: :commentable, dependent: :destroy
  has_many :flagged_items, -> (object) { where(action_taken: 'open') }, as: :monitorable, class_name: 'Flag'

  has_many :photos
  has_many :videos
  has_many :suggestions, as: :suggestible, dependent: :destroy

  has_one :address

  accepts_nested_attributes_for :address


  validates :name, presence: true
  validate :unique_name_and_city

  scope :without_facebook_object_id, -> { where(facebook_object_id: nil) }
  scope :with_facebook_object_id, -> { where.not(facebook_object_id: nil) }

  attr_accessor :existing_photo_id
  before_validation :copy_existing_file

  # sunspot - solr search
  searchable do
    integer :id, multiple: true
    text :name
    string :full_address
    text :full_address
    string :description
    text :acronym
    text :users do
      users.map { |user| user.full_name }
    end
    text :groups do
      groups.map { |group| group.name }
    end
    integer :user_count, stored: true
    integer :group_count, stored: true
    string :publicly_searchable do
      'true'
    end
    text :class_nouns do
      'school'
    end
    string :class_facet do
      'Schools'
    end
    integer :participation_level do
      user_count.to_i + group_count.to_i
    end
    string :facebook_type
    text :facebook_description
  end

  def has_pending_monitor_requests
    monitor_requests.size > 0
  end

  def full_name
    name
  end

  def to_param
    [id, name.parameterize].join("-")
  end

  def full_address
    return if address.nil?
    address.full_address
  end

  def group_count
    groups.count
  end

  def user_count
    users.count
  end

  def battles
    # TODO seems like this should go in the has_many section of this model
    Battle.where('((opponent_type = ? AND opponent_id = ?) OR (challenger_type = ? AND challenger_id = ?))', 'School', self.id, 'School', self.id)
  end

  # thinking this might belong over in the FacebookGraph class
  def add_fb_address(fb_data)
    create_address(
      city: fb_data.city,
      country: fb_data.country,
      latitude: fb_data.latitude.to_s,
      longitude: fb_data.longitude.to_s,
      state: fb_data.state,
      line_one: fb_data.street,
      postal_code: fb_data['zip'] #can't use .zip method
      )
  end

  def unique_name_and_city
    return if address.nil? # no need to check nil
    existing_schools = School.unscoped.where(name: name)
    return if existing_schools.blank?
    return if existing_schools.collect(&:id) == [id] # for updates - if the school is itself
    city_state_array = existing_schools.map { |s| [s.address.try(:city), s.address.try(:state)] }

    if city_state_array.include?([address.city, address.state])
      errors.add(:name, "we already have a school with that name in #{address.city}, #{address.state}")
    end
  end

  def notification_users
    monitors
  end
  
  def acronym
    name.gsub(/[^A-Z]/, '')
  end

  def copy_existing_file
    if @existing_photo_id.present?
      existing_photo = Photo.find(@existing_photo_id)
      self.avatar = existing_photo.file
      @existing_photo_id = nil
    end
  end

  def normalized
    School.normalized(name)
  end

  def self.normalized(text)
    text.gsub(/[^A-Za-z0-9]+/, ' ').downcase
  end
end
