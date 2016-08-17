class DelayedNotificationJob < ActiveJob::Base
  def perform(recipient, serialized_notification)
    recipient.notify(ApplicationNotification.deserialize(serialized_notification))
  end
end
