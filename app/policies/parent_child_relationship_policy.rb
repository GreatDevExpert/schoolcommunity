class ParentChildRelationshipPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @relationship = model
  end

  def approve?
    @current_user != @relationship.requesting_user
  end

  def destroy?
    @current_user == @relationship.parent || @current_user == @relationship.child
  end
end
