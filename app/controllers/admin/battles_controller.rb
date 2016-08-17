class Admin::BattlesController < Admin::BaseController
  before_action :set_battle

  def edit
    raise Pundit::NotAuthorizedError unless BattlePolicy.new(current_user, @battle).override_scores?


    @form = Battles::AddScoresForm.new(@battle)
  end

  def update
    raise Pundit::NotAuthorizedError unless BattlePolicy.new(current_user, @battle).override_scores?

    @form = Battles::AddScoresForm.new(@battle)
    if @form.validate(params[:battles_add_scores])
      @form.save # save form object data
      @battle.post_game unless @battle.closed?
      @battle.save # save form ends_at and new aasm_state
      redirect_to battle_path(@battle), notice: 'Battle Successfully Updated'
    else
      @battle.errors[:base] << "Please select the logo of the winner or draw."
      render :edit
    end
  end

  private
    def set_battle
      @battle = Battle.unscoped.find(params[:id])
    end

    def battle_params
      params.require(:battle).permit(:game_winner_kind, :challenger_score, :opponent_score, :score_detail)
    end
end