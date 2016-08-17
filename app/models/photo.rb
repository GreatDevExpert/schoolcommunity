class Photo < ActiveRecord::Base
  include Monitorable
  include Identifiable
  include FellowshipAssignable
  
  # activity feed
  include PublicActivity::Model

  attr_accessor :existing_photo_id

  belongs_to :user, unscoped: true
  belongs_to :group
  belongs_to :school

  after_initialize :set_current_year

  has_many :comments, as: :commentable, dependent: :destroy
  accepts_nested_attributes_for :comments, reject_if: proc { |attributes| attributes['content'].blank? }
  
  # carrierwave
  mount_uploader :file, ImageUploader

  validates :file, presence: true
  validates :name, presence: true

  before_validation :copy_existing_file

  # sunspot - solr search
  searchable do
    integer :user_id
    integer :school_id
    integer :group_id
    text :comments do
      comments.map { |comment| comment.content }
    end
    text :first_comment do
      comments.first.content unless comments.size == 0
    end
    text :name
    text :year
    text :class_nouns do
      'photo image pic picture'
    end
    string :class_facet do
      'Photos'
    end
    string :publicly_searchable do
      if visibility_type == 'private'
        'false'
      elsif user.blank?
        'false'
      elsif visibility !=  'visible'
        'false'
      else
        'true'
      end
    end
    integer :comment_count
    integer :participation_level do
      comment_count.to_i
    end
  end

  def copy_existing_file
    if @existing_photo_id.present?
      existing_photo = Photo.find(@existing_photo_id)
      CopyCarrierwaveFile::CopyFileService.new(existing_photo, self, :file).set_file
      @existing_photo_id = nil
    end
  end

  def comment_count
    comments.size
  end

  def filename
    File.basename(file.path)
  end

  def battles
    # TODO seems like this should go in the has_many section of this model
    Battle.where('((first_item_type = ? AND first_item_id = ?) OR (second_item_type = ? AND second_item_id = ?))', 'Photo', self.id, 'Photo', self.id)
  end

  def notification_users
    [user]
  end

  def to_param
    [id, name.parameterize].join("-")
  end

  def set_current_year
    self.year = DateTime.now
  end
end
