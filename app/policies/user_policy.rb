class UserPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @viewed_user = model
  end

  def show?
    if @current_user.nil?
      false
    elsif accessing_own_profile?
      true
    elsif @current_user.super_admin?
      true
    elsif adult_accessing_minor? && !friends?
      false
    else
      true
    end
  end

  def new_post?
    can_manage_profile?
  end

  def pending_friend_requests?
    can_manage_profile?
  end

  def send_friend_request?
    return false if @current_user.nil?
    return false if accessing_own_profile?
    return true if @current_user.super_admin?
    return false if friends?
    !adult_accessing_minor?
  end

  def sent_friend_requests?
    can_manage_profile?
  end

  def cancel_my_account?
    can_manage_profile?
  end

  def edit?
    can_manage_profile?
  end

  def new_post?
    accessing_own_profile?
  end

  def update?
    can_manage_profile?
  end

  def suspend_account?
    return false if @current_user.nil? || @viewed_user.super_admin?
    return false if @current_user == @viewed_user
    return false if @viewed_user.suspended?
    @current_user.super_admin?
  end

  def unsuspend_account?
    return false if @current_user.nil?
    return false if @viewed_user.active?
    @current_user.super_admin?
  end

  def send_scrilla?
    friends? && !accessing_own_profile?
  end

  def adjust_scrilla_balance?
    @current_user.super_admin?
  end

  def send_message?
    return false if accessing_own_profile?
    @current_user.super_admin? || friends?
  end

  def remove_rival?
    return false if accessing_own_profile?
    @current_user.already_rival_people?(@viewed_user)
  end

  def add_rival?
    return false if accessing_own_profile?
    @current_user.already_rival_people?(@viewed_user) == false
  end

  def remove_friendship?
    return false if accessing_own_profile?
    return friends?
  end

  private

    def accessing_own_profile?
      @current_user == @viewed_user
    end

    def can_manage_profile?
      if accessing_own_profile?
        true
      elsif @current_user.super_admin?
        true
      else
        false
      end
    end

    def adult_accessing_minor?
      if @current_user.is_adult? && @viewed_user.minor?
        return true
      else
        return false
      end
    end

    def friends?
      @current_user.friend?(@viewed_user)
    end

end
