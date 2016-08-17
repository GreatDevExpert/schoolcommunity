class BattlesController < ApplicationController
  before_action :load_battle, :set_commentable, only: :show

  def new
    @battle = Battle.new
    authorize @battle
  end

  def show
    authorize @battle
    @current_user_pass = current_user.passes.where(battle: @battle).first
  end

  def create
    authorize Battle.new
    kind = params['kind']
    @battle = current_user.battles_started.new(kind: kind)
    
    if @battle.save
      send_to_first_step(kind)
    else
      render :new, error: 'Could not start battle.'
    end
  end

  private

    def send_to_first_step(kind)
      case kind
      when 'this_vs_that'
        redirect_to battle_this_vs_that_path(@battle, 'pick_this', items: 'photos')
      when 'me_vs_you'
        if current_user.rival_people.present?
          redirect_to battle_me_vs_you_path(@battle, 'select_opponent', items: 'rival_people')
        else
          redirect_to battle_me_vs_you_path(@battle, 'select_opponent', items: 'schoolies')
        end
      when 'group_vs_group'
        redirect_to battle_group_vs_group_path(@battle, 'select_group', items: 'groups')
      when 'school_vs_school'
        redirect_to battle_school_vs_school_path(@battle, 'select_school')
      end
    end

    def set_commentable
      @commentable = Battle.unscoped.find(params[:id])
      @comment = Comment.new
      @comments = @commentable.comments
    end

    def load_battle
      @battle = Battle.unscoped.find(params[:id])
      if @battle.hidden? && current_user_is_super_admin? == false
        raise CustomExceptions::FlaggedError
      end
    end

end