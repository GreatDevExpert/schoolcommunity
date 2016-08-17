class FellowshipPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @fellowship = model
    @school = @fellowship.try(:school)
  end

  def join?
    user_logged_in?
  end

  def leave?
    return false unless @current_user
    @current_user.already_associated_with?(@school)
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

  def become_alumni?
    return false unless user_logged_in?
    @fellowship.role == 'student'
  end

  def approve_become_alumni?
    become_alumni?
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

  def destroy?
    return false unless user_logged_in?
    return true if @current_user.super_admin?
    return @current_user == @fellowship.user
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
      elsif @school.nil?
        false
      elsif @school.monitors.blank? #odd, but required to get tests passing
        false
      elsif @school.monitors.pluck(:id).include?(@current_user.id)
        true
      else
        false
      end
    end

end
