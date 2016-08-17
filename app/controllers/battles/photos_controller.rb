class Battles::PhotosController < ApplicationController
  before_filter :load_battle
  
  def new
    @photo = Photo.new
    render layout: false
  end

  def create
    @photo = current_user.photos.new(photo_params)

    if @photo.save
      if params[:item_kind] == 'first_object_type'
        @battle.update_attributes(first_item: @photo, first_item_name: @photo.name)
      elsif params[:item_kind] == 'second_object_type'
        @battle.update_attributes(second_item: @photo, second_item_name: @photo.name, opposing_user: current_user)
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

    def photo_params
      params.require(:photo).permit(:file, :file_cache, :name, :remote_file_url, :description, :year)
    end
end
