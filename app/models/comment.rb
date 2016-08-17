class Comment < ActiveRecord::Base
  include Monitorable
  include PublicActivity::Model

  after_commit :reindex_commentable 
  after_destroy :remove_associated_notifications
  
  belongs_to :commentable, polymorphic: true
  belongs_to :user, unscoped: true
  validates :content, presence: true

  default_scope { order('created_at DESC') }

  def object_commented_on
    commentable 
  end

  def reindex_commentable
    if commentable.class.respond_to?(:reindex)
      Reindex.perform_later(commentable)
    end
  end

  def remove_associated_notifications
    Notification.where(notifier: self).destroy_all
  end

end
