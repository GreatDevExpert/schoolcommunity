class PassPolicy < ApplicationPolicy
  def initialize(current_user, model)
    @current_user = current_user
    @battle = model
  end

  def new?
    can_buy_pass?
  end

  def create?
    can_buy_pass?
  end

  def edit?
    can_change_pass?
  end

  def update?
    can_change_pass?
  end

  private

    def can_buy_pass?
      return false if @current_user.nil?
      return false unless @battle.pregame?
      return false unless @battle.kind == 'school_vs_school'
      if has_not_already_purchased_battle_pass?(@battle)
        true
      else
        false
      end
    end  

    def can_change_pass?
      return false if @current_user.nil?
      return false unless @battle.pregame?
      return false unless @battle.kind == 'school_vs_school'
      if already_purchased_battle_pass?(@battle)
        pass = @battle.passes.where(user_id: @current_user.id).first
        if pass.amount == 500
          false
        else
          true
        end
      else
        false
      end
    end  


    def already_purchased_battle_pass?(battle)
      battle.passes.pluck(:user_id).include?(@current_user.id)
    end

    def has_not_already_purchased_battle_pass?(battle)
      already_purchased_battle_pass?(battle) == false
    end



end