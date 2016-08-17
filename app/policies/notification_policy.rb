class NotificationPolicy < ApplicationPolicy

  def initialize(current_user, notification)
    @current_user = current_user
    @notification = notification
  end
end
