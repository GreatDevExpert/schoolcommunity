class Schools::RivalriesController < ApplicationController
  before_action :load_school

  def add_rival
    @rivalry = Rivalry.where(user: current_user, school: @school).first_or_initialize
    # @rivalry = current_user.rivalries.new(school_id: @school.id)

    if @rivalry.save
      redirect_to :back, notice: "#{@school.name} is now a rival."
    else
      redirect_to :back, alert: "Sorry, you can't mark #{@school.name} as a rival."
    end
  end


  def remove_rival
    @rivalries = current_user.rivalries.where(school_id: @school.id)
    @rivalries.destroy_all

    redirect_to :back, notice: "#{@school.name} is no longer a rival."
  end


  private 
    def load_school
      @school = School.find(params[:id])
    end
end