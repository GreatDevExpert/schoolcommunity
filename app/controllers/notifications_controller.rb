class NotificationsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    if params[:filter] == 'all'
      @notifications = current_user.notifications.where(is_trashed: false)
    else
      @notifications = current_user.notifications.where(is_trashed: false).where("created_at >= ? OR read_at >= ? OR read_at IS NULL", 2.days.ago, 1.hour.ago)
    end
    @notifications = @notifications.order("read_at IS NULL DESC, created_at DESC").page(params[:page]).per(10)
  end

  def mark_all_as_read
    Notification.mark_all_as_read(recipient: current_user)

    respond_to do |format|
      format.json{ render json: {success: true} }
      format.html{ redirect_to notifications_path, notice: "Your notifications have been marked as read." }
    end
  end

  def toggle_read_status
    @notification = Notification.find(params[:id])
    @notification.toggle_read_status!

    respond_to do |format|
      format.json{ render json: {success: true} }
      format.html{ redirect_to notifications_path(filter: 'recent') }
    end
  end

  def recent
    @notifications = current_user.notifications.where(is_trashed: false).where("created_at >= ? OR read_at >= ? OR read_at IS NULL", 2.days.ago, 1.hour.ago).order("read_at IS NULL DESC, created_at DESC").limit(5)
    respond_to do |format|
      format.json { render :json => {:success => true, :html => (render_to_string partial: 'notifications/recent', layout: false, formats: [:html])} }
      format.html {}
    end
  end
end
