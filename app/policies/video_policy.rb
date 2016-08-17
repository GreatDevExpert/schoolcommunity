class VideoPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @video = model
  end

  def show?
    if belongs_to_private_group?
      @current_user && @current_user.is_a_group_member_of?(@video.group)
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
    @current_user != @video.user
  end

  def new?
    @current_user.present?
  end
  
  def create?
    @current_user.present?
  end

  def destroy?
    return false if @current_user.nil?
    @current_user == @video.user || @current_user.super_admin?
  end

  def duplicate?
    return false if @current_user.nil?
    return false if @current_user == @video.user
    !belongs_to_private_group?
  end

  def repost?
    return false if @current_user.nil?
    if @current_user == @video.user
      true
    else
      false
    end
  end

  private
  def belongs_to_private_group?
    return false unless @video.group
    @video.group.visibility_type == 'private'
  end
end
