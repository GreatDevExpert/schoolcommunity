 class Battles::ThisVsThatController < ApplicationController
  include Wicked::Wizard
  before_action :load_battle

  steps :pick_this, :pick_that, :name_items, :finalize_battle
  
  def show
    authorize @battle
    case step

    when :pick_this
      # is they hit back, I want to clear out the first item so the question mark shows in the mini preview.
      @battle.update_attribute(:first_item, nil) if @battle.first_item.present?

      @form = Battles::PickThisForm.new(@battle)
      if params[:q].present?
        @photos = current_user.photos.where("name ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(19)
        @videos = current_user.videos.where("title ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(19)
        @documents = current_user.documents.where("name ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(19)
      else
        @photos = current_user.photos.page(params[:page]).per(19)
        @videos = current_user.videos.page(params[:page]).per(19)
        @documents = current_user.documents.page(params[:page]).per(19)
      end

    when :pick_that
      # is they hit back, I want to clear out the first item so the question mark shows in the mini preview.
      @battle.update_attribute(:second_item, nil) if @battle.second_item.present?

      @form = Battles::PickThatForm.new(@battle)
      if params[:q].present?
        @photos = current_user.photos.where("name ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(19)
        @videos = current_user.videos.where("title ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(19)
        @documents = current_user.documents.where("name ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(19)
      else
        @photos = current_user.photos.page(params[:page]).per(19)
        @videos = current_user.videos.page(params[:page]).per(19)
        @documents = current_user.documents.page(params[:page]).per(19)
      end
    when :name_items
      @form = Battles::NameItemsForm.new(@battle)
    when :finalize_battle
      @form = Battles::FinalizeForm.new(@battle)
    end
    render_wizard
  end

  def update
    authorize @battle
    case step

    when :pick_this
      @form = Battles::PickThisForm.new(@battle)
      @photos = current_user.photos.page(params[:page]).per(19)
      @videos = current_user.videos.page(params[:page]).per(19)
      @documents = current_user.documents.page(params[:page]).per(19)
      if @form.validate(params[:battles_pick_this])
        @form.model.first_item = current_user.send(params[:battles_pick_this][:first_object_type]).find(params[:battles_pick_this][:first_object_id])
        @form.model.first_item_name = @form.model.first_item.name
        @form.save
        redirect_to wizard_path(@next_step, {items: 'photos'})
      else
        @battle.errors[:base] << "Please select a first item."
        render_wizard
      end

    when :pick_that
      @form = Battles::PickThatForm.new(@battle)
      @photos = current_user.photos.page(params[:page]).per(19)
      @videos = current_user.videos.page(params[:page]).per(19)
      @documents = current_user.documents.page(params[:page]).per(19)
      @new_second_item = current_user.send(params[:battles_pick_that][:second_object_type]).find(params[:battles_pick_that][:second_object_id]) unless params[:battles_pick_that][:second_object_id].nil?
      if @form.validate(params[:battles_pick_that])
        @form.model.second_item = @new_second_item
        @form.model.second_item_name = @form.model.second_item.name
        render_wizard @form
      elsif @battle.first_item == @new_second_item
        @battle.errors[:base] << "Please select a different item. That one has already been selected for this battle."
        render_wizard      
      else
        @battle.errors[:base] << "Please select a second item."
        render_wizard
      end

    when :name_items
      @form = Battles::NameItemsForm.new(@battle)
      if @form.validate(params[:battles_name_items])
        render_wizard @form
      else
        render_wizard
      end

    when :finalize_battle
      @form = Battles::FinalizeForm.new(@battle)
      if @form.validate(params[:battles_finalize])
        @battle.set_end_time(params[:battles_finalize][:battle_length])
        @battle.open_for_voting
        render_wizard @form
      else
        render_wizard
      end
    end
  end

  def finish_wizard_path
    flash[:notice] = 'Your Battle Has Started!'
    battle_path(@battle)
  end

  private

    def load_battle
      @battle = Battle.unscoped.find(params[:battle_id])
      raise CustomExceptions::FlaggedError if @battle.visibility != 'visible'
      @next_step = next_step
    end

 end