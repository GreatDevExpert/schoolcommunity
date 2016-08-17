class VotesController < ApplicationController
  before_action :set_battle

  def new_first_item_vote
    check_pundit
    @vote = @battle.votes.new(item: 'first', user: current_user)
    if @vote.save
      Battle.increment_counter(:first_item_vote_count, @battle.id)
      redirect_to @battle, notice: 'Vote recorded'
    else
      redirect_to @battle, error: 'Could not vote'
    end
  end

  def new_second_item_vote
    check_pundit
    @vote = @battle.votes.new(item: 'second', user: current_user)
    if @vote.save
      Battle.increment_counter(:second_item_vote_count, @battle.id)
      redirect_to @battle, notice: 'Vote recorded'
    else
      redirect_to @battle, error: 'Could not vote'
    end
  end

  private

    def check_pundit
      raise Pundit::NotAuthorizedError unless VotePolicy.new(current_user, @battle).new_first_item_vote?
    end

    def set_battle
      @battle = Battle.find(params[:battle_id])
    end

end
