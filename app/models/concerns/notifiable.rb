module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :recipient
  end

  def notify(notification)
    if notification.send_notification?
      send_internal_notification(notification)
      send_email_notification(notification)
    end
  end

  private
  def send_internal_notification(notification)
    notifications.create(body: notification.body, notifier: notification.notifier, uuid: notification.uuid)
  end

  def send_email_notification(notification)
    if respond_to?(:settings) && settings(:settings).email_on_new_notification
      NotificationMailer.new_notification_email(self, notification.body).deliver_later
    end
  end
end
