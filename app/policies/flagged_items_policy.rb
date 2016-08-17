class FlaggedItemsPolicy < ApplicationPolicy

  def initialize(current_user, model)
    @current_user = current_user
    @related_organization = model.monitorable unless model.nil?
  end

  def index?
    return false unless @current_user.present?
    return true if @current_user.super_admin?
    return true if @current_user.is_a_monitor?
    false
  end

  def show?
    user_is_a_monitor?
  end

  def ignore?
    user_is_a_monitor?
  end
  
  def hide_content?
    user_is_a_monitor?
  end

  private

    def user_logged_in?
      return false unless @current_user
      true
    end

    def user_is_a_monitor?
      return false unless @current_user.present?
      return true if @current_user.super_admin? && @related_organization.respond_to?(:monitors) == false #no monitor possible, must be super admin
      return false if @current_user.super_admin? == false && @related_organization.respond_to?(:monitors) == false #no monitor possible, must be super admin
      return true if @current_user.super_admin?
      return false unless @related_organization.present?
      if @related_organization.monitors.blank? #odd, but required to get tests passing
        false
      elsif @related_organization.monitors.pluck(:id).include?(@current_user.id)
        true
      else
        false
      end
    end

end
