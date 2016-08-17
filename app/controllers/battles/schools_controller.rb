class Battles::SchoolsController < ApplicationController
  before_filter :load_battle
  
  def new
    @school = School.new
    render layout: false
  end

  def create
    @school = current_user.schools.new(school_params)
    if @school.save
      if params[:item_kind] == 'challenger'
        @battle.update_attribute(:challenger, @school)
      elsif params[:item_kind] == 'opponent'
        @battle.update_attribute(:opponent, @school)
      end
      redirect_to params[:next_step]
    else
      render :new
    end
  end

  private

    def load_battle
      @battle = Battle.find(params[:battle_id])
    end

    def school_params
      params.require(:school).permit(:name, :description, :visibility_type, :school_id, :avatar, :remote_avatar_url)
    end

end