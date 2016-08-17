class SchoolPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @school = model
  end

  def show?
    if @school.visibility == 'visible'
      true
    elsif @school.visibility == 'needs_approval' && user_is_a_monitor?
      true
    elsif @current_user && @current_user.super_admin?
      true
    else
      false
    end
  end

  def show_activity?
    return true if @current_user.present? && @current_user.super_admin?
    user_is_a_fellow?
  end

  def new?
    user_logged_in?
  end
  
  def create?
    user_logged_in?
  end

  def edit?
    return false unless user_logged_in?
    user_is_a_monitor? || @current_user.super_admin?
  end

  def update?
    edit?
  end

  def approve_monitor?
    edit?
  end

  def destroy?
    false
  end

  def new_post?
    user_is_a_fellow?
  end

  def remove_rival?
    @current_user.already_rival_schools?(@school)
  end

  def add_rival?
    @current_user.already_rival_schools?(@school) == false
  end

  def join?
    user_logged_in?
  end

  def leave?
    return false unless @current_user
    @current_user.already_associated_with?(@school)
  end

  def step_down_as_monitor?
    return false unless @current_user
    if @current_user.super_admin?
      false
    elsif user_is_a_monitor?
      true
    else
      false
    end
  end

  def new_monitor_request?
    return false unless user_logged_in?
    return false if user_is_a_pending_monitor?
    !user_is_a_monitor?
  end

  def leave_as_monitor?
    return false unless user_logged_in?
    user_is_a_monitor?
  end

  private

    def user_logged_in?
      return false unless @current_user
      true
    end

    def user_is_a_fellow?
      return false unless @current_user
      if @school.users.pluck(:id).include?(@current_user.id)
        true
      else
        false
      end
    end


    def user_is_a_monitor?
      return false unless @current_user
      if @school.monitors.blank? #odd, but required to get tests passing
        false
      elsif @school.monitors.pluck(:user_id).include?(@current_user.id)
        true
      else
        false
      end
    end

    def user_is_a_pending_monitor?
      return false unless @current_user
      return false if @school.monitor_requests.blank?
      @school.monitor_requests.pluck(:user_id).include?(@current_user.id)
    end
end
