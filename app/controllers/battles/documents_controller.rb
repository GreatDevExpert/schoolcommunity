class Battles::DocumentsController < ApplicationController
  before_filter :load_battle
  
  def new
    @document = Document.new
    render layout: false
  end

  def create
    @document = current_user.documents.new(document_params)

    if @document.save
      if params[:item_kind] == 'first_object_type'
        @battle.update_attributes(first_item: @document, first_item_name: @document.name)
      elsif params[:item_kind] == 'second_object_type'
        @battle.update_attributes(second_item: @document, first_item_name: @document.name, opposing_user: current_user)
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

    def document_params
      params.require(:document).permit(:file, :file_cache, :name, :remote_file_url, :description, :year)
    end
end
