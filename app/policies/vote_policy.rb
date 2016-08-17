class VotePolicy < ApplicationPolicy

  def initialize(current_user, model)
    @current_user = current_user
    @battle = model
  end

  def new_first_item_vote?
    can_vote?
  end

  def new_second_item_vote?
    can_vote?
  end

  private
  
    def can_vote?
      return false unless @current_user.present?
      return false unless @battle.open_for_voting?
      if @current_user.has_not_voted_on?(@battle)
        true
      else
        false
      end
    end

end
