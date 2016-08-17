class NotificationsReaderController < ApplicationController
  def show
    notification = Notification.find_by(uuid: params[:id])
    if notification
      notification.mark_as_read!
    end
    
    if params[:url]
      redirect_to params[:url]
    else
      redirect_to notifications_path
    end
  end
end
