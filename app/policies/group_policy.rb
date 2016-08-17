class GroupPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @group = model
  end

  def show?
    return true if @current_user && @current_user.super_admin?
    case @group.visibility_type
    when "public"
      true
    when "moderated"
      true
    when "private"
      user_is_a_member? || user_is_invited?
    else
      raise "Unexpected group visibility #{@group.visiblity}"
    end
  end

  def show_membership?
    return true if @current_user && @current_user.super_admin?
    case @group.visibility_type
    when "public"
      true
    when "moderated"
      user_is_a_member?
    when "private"
      user_is_a_member?
    else
      raise "Unexpected group visibility #{@group.visiblity}"
    end
  end

  def show_content?
    return true if @current_user && @current_user.super_admin?
    case @group.visibility_type
    when "public"
      true
    when "moderated"
      user_is_a_member?
    when "private"
      user_is_a_member?
    else
      raise "Unexpected group visibility #{@group.visiblity}"
    end
  end

  def post_content?
    user_is_a_member? || (@current_user && @current_user.super_admin?)
  end

  def new_post?
    post_content?
  end

  def send_invitation?
    user_is_a_member? || (@current_user && @current_user.super_admin?)
  end

  def new_monitor_request?
    return false unless user_logged_in?
    return false if user_is_a_monitor?
    return false if monitor_request_pending?

    if @group.visibility_type == 'public'
      true
    else
      user_is_a_member?
    end
  end

  def approve_join?
    return false if @current_user.nil?
    user_is_a_monitor? || @current_user.super_admin?
  end

  def approve_monitor?
    return false if @current_user.nil?
    user_is_a_monitor? || @current_user.super_admin?
  end

  def new?
    user_logged_in?
  end
  
  def create?
    user_logged_in?
  end

  def edit?
    return false if @current_user.nil?
    user_is_a_monitor? || @current_user.super_admin?
  end

  def update?
    return false if @current_user.nil?
    user_is_a_monitor? || @current_user.super_admin?
  end

  def remove_rival?
    return false if @current_user.nil?
    @current_user.already_rival_groups?(@group)
  end

  def add_rival?
    return false if @current_user.nil?
    @current_user.already_rival_groups?(@group) == false
  end

  def confirm_destroy?
    return false if @current_user.nil?
    user_is_a_monitor? || @current_user.super_admin?
  end

  def destroy?
    case @group.visibility_type
    when "public"
      @current_user.super_admin?
    when "moderated"
      @current_user.super_admin? || user_is_last_monitor?
    when "private"
      @current_user.super_admin? || user_is_last_monitor?
    else
      raise "Unexpected group visibility #{@group.visiblity}"
    end
  end

  def leave_group?
    # Must step down as monitor before leaving
    return false if user_is_a_monitor? 

    user_is_a_member?
  end

  def leave_as_monitor?
    if @group.visibility_type == 'public'
      user_is_a_monitor?
    else
      user_is_a_monitor? && !user_is_last_monitor?
    end
  end

  private

    def user_logged_in?
      return false unless @current_user
      true
    end

    def user_is_a_member?
      return false unless @current_user
      if @group.members.pluck(:id).include?(@current_user.id)
        true
      else
        false
      end
    end

    def user_is_invited?
      return false unless @current_user
      @group.invited.pluck(:id).include?(@current_user.id)
    end

    def user_is_a_monitor?
      return false unless @current_user
      return false if @group.monitors.blank?

      if @group.monitors.pluck(:id).include?(@current_user.id)
        true
      else
        false
      end
    end

    def user_is_last_monitor?
      user_is_a_monitor? && @group.monitors.count == 1
    end

    def monitor_request_pending?
      return false unless @current_user
      @group.monitor_requests.where(user: @current_user).exists?
    end
end
