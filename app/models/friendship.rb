class Friendship < ActiveRecord::Base
  after_commit :reindex_user #so friend_count is updated on both people

  belongs_to :user
  belongs_to :friend, class_name: "User"
  has_many :comments, as: :commentable, dependent: :destroy

  validates_associated :user, :friend
  validate :user_not_own_friend
  validates_uniqueness_of :user_id, :scope => :friend_id

  # activity feed
  include PublicActivity::Model
  tracked owner: -> (controller, model) { model.user }, recipient: -> (controller, model) { model.friend }, only: [:create]

  def notification_users
    [user]
  end

  def self.remove_friendship(user1:, user2:)
    Friendship.where(user: user1, friend: user2).destroy_all
    Friendship.where(user: user2, friend: user1).destroy_all
  end

  private

    def user_not_own_friend
      errors.add(:user, "can not be own friend") if user_id == friend_id
    end

    def reindex_user
      # TODO: Reindex user on friendship create or destroy
      #Solr::Reindex.perform_later(user)
      #Solr::Reindex.perform_later(friend)
    end

end
