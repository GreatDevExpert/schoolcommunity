class Battles::GroupsController < ApplicationController
  before_filter :load_battle
  
  def new
    @group = Group.new
    render layout: false
  end

  def create
    @group = current_user.groups.new(group_params)
    if @group.save
      if params[:item_kind] == 'challenger'
        @battle.update_attribute(:challenger, @group)
      elsif params[:item_kind] == 'opponent'
        @battle.update_attribute(:opponent, @group)
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

    def group_params
      params.require(:group).permit(:name, :description, :visibility_type, :school_id, :avatar, :remote_avatar_url)
    end

end