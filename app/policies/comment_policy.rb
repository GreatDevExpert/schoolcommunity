class CommentPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @comment = model
  end

  def new?
    @current_user.present?
  end

  def destroy?
    return false if @current_user.nil?
    @current_user == @comment.user || @current_user.super_admin?
  end

  def create?
    @current_user.present?
  end

end
