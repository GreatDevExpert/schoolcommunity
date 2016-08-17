class Invitation
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :sender, :recipients, :message, :target

  def initialize(attributes = {})
    attributes.each do |name, value|
      send "#{name}=", value
    end
  end

  def persisted?
    false
  end

  def save
    return false unless valid?

    recipients.select{ |u| u.kind_of?(User) }.each do |recipient|
      # Mark user as invited
      target.add_invited_user(recipient)

      # Build and send notification
      notification = GroupInvitationNotification.new(sender: sender, recipient: recipient, message: message, group: target)
      notification.notify
    end
  end
end
