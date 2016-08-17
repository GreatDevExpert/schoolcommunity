class ScrillaRequest < ActiveRecord::Base
  include AASM

  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  validates_presence_of :sender, :recipient
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validate :sender_and_recipient_are_friends

  aasm do
    state :pending, :initial => true
    state :complete, :before_enter => :before_complete

    event :complete do
      transitions from: :pending, to: :complete, guard: :valid?
    end
  end

  def sender_and_recipient_are_friends
    if sender && recipient && !sender.friend?(recipient)
      errors.add(:recipient, "can only send requests to friends")
    end
  end

  private
  def before_complete
    ScrillaRequestNotification.new(recipient: recipient, requester: sender, scrilla_request: self).notify
  end
end
