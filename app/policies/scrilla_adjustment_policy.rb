class ScrillaAdjustmentPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @model = model
  end

  def new?
    @current_user && @current_user.super_admin?
  end

  alias_method :create?, :new?
end
