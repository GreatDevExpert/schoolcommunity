class InfoController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: :home # For embedding in facebook iframe

  def home
    if current_user
      @activities = CombinedActivityQuery.new(current_user).activities.page(params[:page]).per(20)
    elsif params[:fb_source] == 'notification' && params[:request_ids]
      # Store request id for later retrieval
      cookies[:facebook_request_ids] = params[:request_ids]
    end
  end

  def about
  end

  def data_use_policy
  end

  def cookie_policy
  end

  def privacy_policy
  end

  def tos
  end

  def coppa
  end

  def dcma
  end

  def graduation_chart
    today = Date.today
    # Once we hit September, assume we're talking about the next year
    if today.month >= 9
      @current_year = today.year + 1
    else
      @current_year = today.year
    end
  end
end
