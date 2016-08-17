class MembershipPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @membership = model
    @group = @membership.group
  end

  def join?
    user_logged_in?
  end

  def leave?
    user_logged_in?
  end

  def new_monitor_request?
    if user_is_a_monitor?
      false
    elsif user_logged_in?
      true
    else
      false
    end
  end

  def approve_monitor?
    user_is_a_monitor?
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

  private

    def user_logged_in?
      return false unless @current_user
      true
    end

    def user_is_a_monitor?
      return false unless @current_user
      if @current_user.super_admin?
        true
      elsif @group.nil?
        false
      elsif @group.monitors.blank? #odd, but required to get tests passing
        false
      elsif @group.monitors.pluck(:id).include?(@current_user.id)
        true
      else
        false
      end
    end

end