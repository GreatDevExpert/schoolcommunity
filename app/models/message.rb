class Message
  include ActiveModel::Model
  attr_accessor :sender, :recipient, :message

  validates_presence_of :sender, :recipient, :message
  validate :sender_must_be_user
  validate :recipient_must_be_user
  validate :sender_must_have_permission

  def save
    return false unless valid?

    notification = MessageNotification.new(sender: sender, recipient: recipient, message: message)
    notification.notify
  end

  private
  def sender_must_be_user
    unless @sender.kind_of?(User)
      errors.add(:sender, "must be a user")
    end
  end

  def recipient_must_be_user
    unless @recipient.kind_of?(User)
      errors.add(:recipient, "must be a user")
    end
  end

  def sender_must_have_permission
    return nil unless sender.kind_of?(User) && recipient.kind_of?(User)
    unless Pundit.policy!(sender, recipient).send_message?
      errors.add(:recipient, "must be schoolies")
    end
  end

end
