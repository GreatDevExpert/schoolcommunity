class Users::RivalriesController < ApplicationController
  before_action :load_user

  def add_rival
    # @rivalry = current_user.rivalries.new(rival_user_id: @user.id)
    @rivalry = Rivalry.where(user: current_user, rival_user: @user).first_or_initialize


    if @rivalry.save
      redirect_to :back, notice: "#{@user.full_name} is now a rival."
    else
      redirect_to :back, alert: "Sorry, you can't mark #{@user.name} as a rival."
    end
  end

  def remove_rival
    @rivalries = current_user.rivalries.where(rival_user_id: @user.id)
    @rivalries.destroy_all

    redirect_to :back, notice: "#{@user.full_name} is no longer a rival."
  end

  private 
    def load_user
      @user = User.find(params[:id])
    end
end