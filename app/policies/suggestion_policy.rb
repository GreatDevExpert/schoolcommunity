class SuggestionPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @suggestion = model
    @suggestible = @suggestion.try(:suggestible)
  end

  def index?
    return false unless @current_user.present?
    return true if @current_user.super_admin?
    return true if @current_user.is_a_monitor?
    false
  end

  def approve_or_decline?
    user_is_a_monitor?
  end

  private

    def user_is_a_monitor?
      return false unless @current_user
      return true if @current_user.super_admin?
      return false if @suggestible.monitors.blank?
      if @suggestible.monitors.pluck(:id).include?(@current_user.id)
        true
      else
        false
      end
    end

end