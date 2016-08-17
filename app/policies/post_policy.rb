class PostPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @post = model
  end

  def show?
    if belongs_to_private_group?
      @current_user && @current_user.is_a_group_member_of?(@post.group)
    else
      true
    end
  end

  def share?
    !belongs_to_private_group?
  end

  def flag?
    return false unless @current_user.present?
    return true if @current_user.super_admin?
    @current_user != @post.user
  end

  def new?
    @current_user.present?
  end

  def create?
    return false unless @current_user
    if @current_user.super_admin?
      true
    elsif @post.school.present?
      @post.school.users.pluck(:id).include?(@current_user.id)
    elsif @post.group.present?
      @post.group.members.pluck(:id).include?(@current_user.id)
    elsif @current_user.present?
      true
    else
      false
    end
  end

  def destroy?
    return false if @current_user.nil?
    @current_user == @post.user || @current_user.super_admin?
  end

  private
  def belongs_to_private_group?
    return false unless @post.group
    @post.group.visibility_type == 'private'
  end
end
