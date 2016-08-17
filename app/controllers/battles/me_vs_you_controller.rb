 class Battles::MeVsYouController < ApplicationController
  include Wicked::Wizard
  before_action :load_battle
  
  steps :select_opponent, :pick_this, :finalize_challenge, :pick_that, :accept_challenge

  def show
    authorize @battle
    case step

    when :select_opponent
      @form = Battles::SelectOpponentForm.new(@battle)
      filter = params[:items]

      if params[:q].present?
        if filter == 'rival_people'
          @users = current_user.rival_people.where(['first_name ILIKE ? OR last_name ILIKE ?', "%#{params[:q]}%", "%#{params[:q]}%"]).page(params[:page]).per(10)
        else
          @users = current_user.friends.where(['first_name ILIKE ? OR last_name ILIKE ?', "%#{params[:q]}%", "%#{params[:q]}%"]).page(params[:page]).per(10)
        end
      else
        if filter == 'rival_people'
          @users = current_user.rival_people.page(params[:page]).per(10)
        else
          @users = current_user.friends.page(params[:page]).per(10)
        end
      end

    when :pick_this
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

    when :finalize_challenge
      @form = Battles::FinalizeChallengeForm.new(@battle)

    when :pick_that
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


    when :accept_challenge
      @form = Battles::AcceptChallengeForm.new(@battle)
    end

    render_wizard
  end

  def update
    authorize @battle
    filter = params[:items]

    case step
    when :select_opponent
      @form = Battles::SelectOpponentForm.new(@battle)
      if filter == 'rival_people'
        @users = current_user.friends.page(params[:page]).per(10)
      else
        @users = current_user.rival_people.page(params[:page]).per(10)
      end

      if @form.validate(params[:battles_select_opponent])
        @battle.opposing_user = current_user.send(params[:battles_select_opponent][:opponent_object_type]).find(params[:battles_select_opponent][:opponent_object_id])
        @form.save
        redirect_to wizard_path(@next_step, {items: 'photos'})
      else
        @battle.errors[:base] << "Please select an opponent."
        render_wizard
      end

    when :pick_this
      @form = Battles::PickThisForm.new(@battle)
      @photos = current_user.photos.page(params[:page]).per(19)
      @videos = current_user.videos.page(params[:page]).per(19)
      @documents = current_user.documents.page(params[:page]).per(19)
      
      if @form.validate(params[:battles_pick_this])
        @form.model.first_item = current_user.send(params[:battles_pick_this][:first_object_type]).find(params[:battles_pick_this][:first_object_id])
        @form.model.first_item_name = @form.model.first_item.name
        render_wizard @form
      else
        @battle.errors[:base] << "Please select a first item."
        render_wizard
      end

    when :finalize_challenge
      @form = Battles::FinalizeChallengeForm.new(@battle)
      if @form.validate(params[:battles_finalize_challenge])
        @form.save
        # now auto add the rival user
        Rivalry.where(user: current_user, rival_user: @battle.opposing_user).first_or_create
        # add a vote for the user
        @battle.votes.create(item: 'first', user: current_user)
        # and increment the vote count for the first vote
        Battle.increment_counter(:first_item_vote_count, @battle.id)
        @battle.challenge_opponent
        @battle.save #save save again to save aasm_state

        redirect_to battle_path(@battle)
      else
        render_wizard
      end

    when :pick_that
      @form = Battles::PickThatForm.new(@battle)
      @photos = current_user.photos.page(params[:page]).per(19)
      @videos = current_user.videos.page(params[:page]).per(19)
      @documents = current_user.documents.page(params[:page]).per(19)

      if @form.validate(params[:battles_pick_that])
        @form.model.second_item = current_user.send(params[:battles_pick_that][:second_object_type]).find(params[:battles_pick_that][:second_object_id])
        @form.model.second_item_name = @form.model.second_item.name
        render_wizard @form.model
      else
        @battle.errors[:base] << "Please select an item."
        render_wizard
      end

    when :accept_challenge
      @form = Battles::AcceptChallengeForm.new(@battle)
      if @form.validate(params[:battles_accept_challenge])
        @battle.challenge_accepted
        @battle.set_end_time(@battle.battle_length)
        # now auto add the rival user
        Rivalry.where(user: current_user, rival_user: @battle.owner).first_or_create
        # add a vote for the user
        @battle.votes.create(item: 'second', user: current_user)
        # and increment the vote count for the first vote
        Battle.increment_counter(:second_item_vote_count, @battle.id)

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
    end

end