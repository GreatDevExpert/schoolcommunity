class Document < ActiveRecord::Base
  include Monitorable
  include Identifiable
  include FellowshipAssignable

  belongs_to :user, unscoped: true
  belongs_to :group
  belongs_to :school
  has_many :comments, as: :commentable, dependent: :destroy

  attr_accessor :existing_document_id

  after_commit :generate_box_view_uuid, on: :create
  after_initialize :set_current_year
  before_validation :copy_existing_file

  def generate_box_view_uuid
    GenerateBoxViewUuidJob.perform_later(self)
  end

  def preview
    DocumentPreview.new(self)
  end

  # carrierwave
  mount_uploader :file, DocumentUploader
  mount_uploader :document_preview, DocumentPreviewUploader

  # activity feed
  include PublicActivity::Model

  validates :file, presence: true
  validates :user_id, presence: true
  validates :name, presence: true

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
    text :filename
    text :name
    text :year
    text :class_nouns do
      'doc document files'
    end
    string :class_facet do
      'Documents'
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

  def comment_count
    comments.size
  end

  def filename
    File.basename(file.path)
  end

  def notification_users
    [user]
  end

  def comment_count
    comments.size
  end

  def to_param
    [id, name.parameterize].join("-")
  end

  def set_current_year
    self.year = DateTime.now
  end

  def copy_existing_file
    if @existing_document_id.present?
      existing_document = Document.find(@existing_document_id)
      CopyCarrierwaveFile::CopyFileService.new(existing_document, self, :file).set_file
    end
  end
end
