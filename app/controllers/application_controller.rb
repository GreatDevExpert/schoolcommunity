class ApplicationController < ActionController::Base
  include PublicActivity::StoreController

  include Pundit
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :store_location
  before_filter :update_sanitized_params, if: :devise_controller?
  before_filter :redirect_based_on_state, unless: :devise_controller?
  before_filter :allow_iframe_requests

  helper_method :notification_count, :current_user_is_super_admin?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from CustomExceptions::FlaggedError, with: :item_has_been_flagged

  # work around for devise and strong parameters
  def update_sanitized_params
    devise_parameter_sanitizer.for(:account_update) {|u| u.permit(:first_name, :last_name, :birthday, :avatar, :postal_code, :city_description, :email, :existing_photo_id)}
  end

  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    if params[:user] && params[:user][:redirect_to_path]
      # also doing this in the OmniauthCallbacksController - for modal redirects using oauth
      # when using modals this is helpful for storing a redirect path
      session[:previous_url] = params[:user][:redirect_to_path]
    elsif (request.fullpath != "/users/sign_in" &&
        request.fullpath != "/" &&
        request.fullpath != "/users/sign_up" &&
        request.fullpath != "/users/password" &&
        request.fullpath != "/users/sign_out" &&
        request.fullpath != "/facebook_payments" &&
        request.fullpath != "/facebook_payments/new" &&
        request.fullpath.exclude?('/users/auth/') && #for oauth redirect
        request.fullpath.exclude?('users/password') && #for oauth redirect
        !request.xhr?) # don't store ajax calls
      session[:previous_url] = request.fullpath 
    end
  end

  def stored_location
    session[:previous_url] || root_url
  end

  def current_user_is_super_admin?
    return false if current_user.blank?
    current_user.super_admin?
  end

  def after_sign_in_path_for(resource)
    # devise override for redirecting to next step of on boarding process
    # if request.env['omniauth.origin'] && current_user.state != 'active'
    if request.env['omniauth.origin'] && current_user.state == 'confirm_profile'
      onboarding_path(:confirm_profile)
    else
      session[:previous_url] || root_path
    end
  end

  def redirect_based_on_state
    return if current_user.nil?
    return if current_user.active?
    return if controller_name == 'fellowships' #allow the user to leave school on sign up
    if current_user.state == 'confirm_profile' && redirect_not_current_path(onboarding_path(:confirm_profile))
        redirect_to onboarding_path(:confirm_profile)
    elsif current_user.state == 'find_a_school' && !request.original_fullpath.include?('/onboarding')
      redirect_to onboarding_path(:find_a_school)
    elsif current_user.state == 'find_friends' && !request.original_fullpath.include?('/onboarding')
      redirect_to onboarding_path(:find_friends)
    elsif current_user.state == 'mission_statement' && !request.original_fullpath.include?('/onboarding')
      redirect_to onboarding_path(:mission_statement)
    end
  end

  def notification_count
    if current_user
      @notification_count ||= Notification.where(recipient: current_user).where("read_at IS NULL").where(is_trashed: false).count 
    end
  end

  private 

    def redirect_not_current_path(desired_redirect_path)
      request.original_fullpath != desired_redirect_path
    end

    def asset_url(asset)
      ActionController::Base.helpers::asset_url(asset, host: Rails.application.config.internet_accessible_url)
    end

    def user_not_authorized
      if current_user.present?
        flash[:error] = "You are not authorized to perform this action."
        redirect_to(request.referrer || root_url)
      else
        flash[:error] = "Please sign into your Myschool account."
        redirect_to root_url
      end
    end

    def item_has_been_flagged
      flash[:error] = "This item has been flagged and can not be viewed at the moment."
      redirect_to(request.referrer || root_path)
    end

    # For embedding in a facebook iframe
    def allow_iframe_requests
      response.headers.delete('X-Frame-Options')
    end

end
