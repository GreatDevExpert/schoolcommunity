class Battles::VideosController < ApplicationController
  before_filter :load_battle
  
  def new
    @video = Video.new
    render layout: false
  end

  def create
    @video = current_user.videos.new(video_params)
    @video.pull_details

    if @video.save
      if params[:item_kind] == 'first_object_type'
        @battle.update_attribute(:first_item, @video, first_item_name: @video.title)
      elsif params[:item_kind] == 'second_object_type'
        @battle.update_attributes(second_item: @video, first_item_name: @video.title, opposing_user: current_user)
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

    def video_params
      params.require(:video).permit(:url, :year, :title)
    end
end
