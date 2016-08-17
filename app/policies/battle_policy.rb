class BattlePolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @battle = model
  end

  def new?
    @current_user.present?
  end

  def index?
    @current_user.present?
  end

  def show?
    can_see_battle?
  end

  def override_scores?
    return false unless @current_user.present?
    return false unless @current_user.super_admin?
    if @battle.kind == 'school_vs_school' && ['needs_scores', 'closed'].include?(@battle.aasm_state)
      true
    else
      false
    end
  end

  def update?
    return false unless @current_user.present?
    if @battle.draft? && @current_user == @battle.owner
      true
    elsif @current_user == @battle.opposing_user && @battle.challenge_pending?
      true #for me_vs_you battles
    elsif @battle.challenge_pending? && user_is_a_member_of_opponent?
      true  #for group vs group and school vs school battles
    elsif @battle.needs_scores? && @current_user == @battle.owner
      true
    else
      false
    end
  end

  def create?
    @current_user.present?
  end

  private

    def can_see_battle?
      return false unless @current_user.present?
      if @current_user.super_admin?
        true
      elsif @current_user == @battle.owner
        true
      elsif @battle.challenge_pending? && @current_user == @battle.opposing_user
        true #for me_vs_you battles
      elsif @battle.challenge_pending? && user_is_a_member_of_opponent?
        true  #for group vs group and school vs school battles
      elsif @battle.open_for_voting? && user_is_a_member_of_opponent?
        true  #for group vs group and school vs school battles
      elsif user_is_a_member_of_opponent? && @battle.open_for_voting? 
        true #for group vs group and school vs school battles
      elsif user_is_a_member_of_challenger? && @battle.open_for_voting? 
        true #for group vs group and school vs school battles
      elsif @battle.open_for_voting? && @current_user == @battle.opposing_user
        true
      elsif @current_user.friend?(@battle.owner) && @battle.closed? 
        true
      elsif @current_user.friend?(@battle.owner) && @battle.open_for_voting? 
        true
      elsif @battle.closed? && @current_user == @battle.opposing_user
        true
      elsif @battle.kind == 'school_vs_school' && @battle.draft? == false
        true
      else
        false
      end
    end

    def user_is_a_member_of_opponent?
      return false if @battle.opponent.nil?
      return false if @battle.opponent.is_a?(User) #they will not have members
      if @battle.opponent.is_a?(Group) && @battle.opponent.members.pluck(:id).include?(@current_user.id)
        true
      elsif @battle.opponent.is_a?(School) && @battle.opponent.fellowships.pluck(:id).include?(@current_user.id)
        true
      else
        false
      end
    end

    def user_is_a_member_of_challenger?
      return false if @battle.challenger.nil?
      return false if @battle.challenger.is_a?(User) #they will not have members
      if @battle.opponent.is_a?(Group) && @battle.opponent.members.pluck(:id).include?(@current_user.id)
        true
      elsif @battle.opponent.is_a?(School) && @battle.opponent.fellowships.pluck(:id).include?(@current_user.id)
        true
      else
        false
      end
    end
end
