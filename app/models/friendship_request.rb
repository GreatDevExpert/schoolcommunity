class FriendshipRequest < ActiveRecord::Base
  include AASM
  include Rails.application.routes.url_helpers

  belongs_to :user
  belongs_to :friend, class_name: "User"

  after_create :remove_friendship_recommendations

  validates_associated :user, :friend
  validate :user_not_friend_requesting_self
  validate :user_not_already_friend
  validates_uniqueness_of :user_id, :scope => :friend_id

  aasm :column => 'status' do
    state :pending, initial: true, before_enter: :send_notifications
    state :ignored
    state :approved

    event :approve, after: -> { convert_to_friendship } do
      transitions from: :pending, to: :approved
    end

    event :ignore do
      transitions from: :pending, to: :ignored
    end
  end

  private
  def user_not_friend_requesting_self
    errors.add(:user, "can not be own friend") if user_id == friend_id
  end

  def user_not_already_friend
    if Friendship.where(user_id: user_id, friend_id: friend_id).count > 0
      errors.add(:user, "user already friend")
    end
  end

  def convert_to_friendship
    Friendship.create(user: user, friend: friend)
    Friendship.create(user: friend, friend: user)

    FriendshipApprovedNotification.new(recipient: user, friend: friend).notify

    destroy!
  end

  def remove_friendship_recommendations
    FriendshipRecommendation.where(user: user).where(recommended_friend: friend).destroy_all
    FriendshipRecommendation.where(user: friend).where(recommended_friend: user).destroy_all
  end

  def send_notifications
    if user && friend
      FriendshipRequestNotification.new(requestor: user, recipient: friend).notify
    end
  end
end
