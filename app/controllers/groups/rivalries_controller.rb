class Groups::RivalriesController < ApplicationController
  before_action :load_group

  def add_rival
    authorize @group
    # @rivalry = current_user.rivalries.new(group: @group)
    @rivalry = Rivalry.where(user: current_user, group: @group).first_or_initialize

    if @rivalry.save
      redirect_to :back, notice: "#{@group.name} is now a rival."
    else
      redirect_to :back, alert: "Sorry, you can't mark #{@group.name} as a rival."
    end
  end

  def remove_rival
    @rivalries = current_user.rivalries.where(group_id: @group.id)
    authorize @group
    @rivalries.destroy_all
    redirect_to :back, notice: "#{@group.name} is no longer a rival."
  end

  private 
    def load_group
      @group = Group.find(params[:id])
    end
end