class Video < ActiveRecord::Base
  include Monitorable
  include Identifiable
  include FellowshipAssignable

  belongs_to :user, unscoped: true
  belongs_to :group
  belongs_to :school
  has_many :comments, as: :commentable, dependent: :destroy

  attr_accessor :existing_video_id

  after_initialize :set_current_year

  validates :url, presence: true
  validate :acceptable_providers
  validates :title, presence: true

  before_validation :copy_existing_file

  ACCEPTABLE_PROVIDERS = ['youtube.com', 'dailymotion.com', 'vimeo.com']

  # activity feed
  include PublicActivity::Model

  # sunspot - solr search
  searchable do
    integer :user_id
    integer :school_id
    integer :group_id
    text :title
    text :year
    text :comments do
      comments.map { |comment| comment.content }
    end
    text :first_comment do
      comments.first.content unless comments.size == 0
    end
    text :class_nouns do
      'video vid clip'
    end
    string :class_facet do
      'Videos'
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
      comment_count
    end

  end

  #for sunspot search
  def name
    title
  end

  def comment_count
    comments.size
  end


  def battles
    # TODO seems like this should go in the has_many section of this model
    Battle.where('((first_item_type = ? AND first_item_id = ?) OR (second_item_type = ? AND second_item_id = ?))', 'Video', self.id, 'Video', self.id)
  end

  def pull_details
    return unless from_acceptable_host?
    video_data = VideoInfo.new(url)
    self.video_id = video_data.video_id
    self.embed_url = video_data.embed_url
    self.thumbnail_large = video_data.thumbnail_large
    self.thumbnail_medium = video_data.thumbnail_medium
    self.thumbnail_small = video_data.thumbnail_small
    self.embed_code = video_data.embed_code
    #self.title = video_data.title
    self.provider = video_data.provider
    self.description = video_data.description
  end

  def short_description
    description && description.truncate(270)
  end

  def notification_users
    [user]
  end

  def set_current_year
    self.year = DateTime.now
  end

  def copy_existing_file
    if @existing_video_id.present?
      existing_video = Video.find(@existing_video_id)
      self.url              = existing_video.url
      self.video_id         = existing_video.video_id
      self.embed_url        = existing_video.embed_url
      self.thumbnail_large  = existing_video.thumbnail_large
      self.thumbnail_medium = existing_video.thumbnail_medium
      self.thumbnail_small  = existing_video.thumbnail_small
      self.provider         = existing_video.provider
      self.embed_code       = existing_video.embed_code
    end
  end

  private

    def acceptable_providers
      unless from_acceptable_host?
        errors.add(:url, "must be from youtube, vimeo or dailymotion")
        # send matt and I an email letting us know the url of other uploads
        AdminMailer.error_alert("#{user.full_name} wanted to upload video from #{url}").deliver_now
      end
    end

    def from_acceptable_host?
      return false if url.blank?
      uri = URI.parse(url)
      domain = PublicSuffix.parse(uri.host)
      ACCEPTABLE_PROVIDERS.include?(domain.domain)
    end



end
