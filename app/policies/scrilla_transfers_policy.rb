class ScrillaTransfersPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @user_being_viewed = model
  end

  def new?
    return false if @current_user.nil?
    true
  end

  def create?
    return false if @current_user.nil?
    true
  end

  def index?
    return false if @current_user.nil?
    return true if @current_user.super_admin?
    return true if @current_user == @user_being_viewed
    false
  end

  alias_method :create?, :new?
end
