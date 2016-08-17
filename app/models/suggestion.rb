class Suggestion < ActiveRecord::Base
  include PublicActivity::Model
  mount_uploader :avatar, AvatarUploader

  attr_accessor :existing_photo_id

  before_validation :copy_existing_file

  belongs_to :user, unscoped: true
  belongs_to :resolving_user, class: User, foreign_key: :resolving_user_id
  belongs_to :suggestible, polymorphic: true

  ALLOWED_KINDS = %w(logo about)
  validates :kind, presence: true, inclusion: { in: ALLOWED_KINDS }
  validates :avatar, presence: true, if: Proc.new { |s| s.kind == 'logo' }
  validates :content, presence: true, if: Proc.new { |s| s.kind == 'about' }


  def copy_existing_file
    if @existing_photo_id.present?
      existing_photo = Photo.find(@existing_photo_id)
      self.avatar = existing_photo.file
      @existing_photo_id = nil
    end
  end


end
