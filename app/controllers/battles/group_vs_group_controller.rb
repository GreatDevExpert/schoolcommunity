 class Battles::GroupVsGroupController < ApplicationController
  include Wicked::Wizard
  before_action :load_battle

  steps :select_group, :find_and_join_group, :select_group_opponent, :pick_this, :finalize_challenge, :pick_that, :accept_challenge
  
  def show
    authorize @battle
    case step

    when :select_group
      @form = Battles::SelectGroupForm.new(@battle)
      if params[:q].present?
        @groups = current_user.groups.where("name ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(19)
      else
        @groups = current_user.groups.page(params[:page]).per(19)
      end

    when :find_and_join_group
      unless params[:show_find_and_join] == 'true'
        if current_user.rival_groups.present?
          skip_step(items: 'rival_groups')
        else
          skip_step(items: 'groups')
        end
      end

      @form = Battles::FindAndJoinGroupForm.new(@battle)

      if params[:q].present?
        @groups = Group.publicly_visible.where("name ILIKE ?" , "%#{params[:q]}%").where.not(id: current_user.groups.pluck(:id)).page(params[:page]).per(3)
      else
        @groups = Group.publicly_visible.where.not(id: current_user.groups.pluck(:id)).page(params[:page]).per(3)
      end

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

    when :select_group_opponent
      @form = Battles::SelectGroupOpponentForm.new(@battle)
      filter = params[:items]

      if params[:q].present?
        if filter == 'rival_groups'
          @groups = current_user.rival_groups.where("name ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(10)
        else
          @groups = Group.publicly_visible.where("name ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(19)
        end
      elsif filter.present?
        if filter == 'rival_groups'
          @groups = current_user.rival_groups.page(params[:page]).per(10)
        else
          @groups = Group.publicly_visible.page(params[:page]).per(19)
        end
      else
        @groups = Group.publicly_visible.page(params[:page]).per(19)
      end
    when :finalize_challenge
      @form = Battles::FinalizeChallengeForm.new(@battle)
    when :pick_that
      @form = Battles::PickThatForm.new(@battle)
      # TODO probably move these to a policy
      jump_to(:wicked_finish) unless current_user.is_a_group_member_of?(@battle.opponent)
      if current_user != @battle.opposing_user && @battle.second_item.present?
        jump_to(:wicked_finish)
      end

      
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
      # TODO probably move these to a policy
      jump_to(:wicked_finish) unless current_user.is_a_group_member_of?(@battle.opponent)
      if current_user != @battle.opposing_user && @battle.second_item.present?
        jump_to(:wicked_finish)
      end

      @form = Battles::AcceptChallengeForm.new(@battle)
    end

    render_wizard
  end

  def update
    authorize @battle
    case step

    when :select_group
      @form = Battles::SelectGroupForm.new(@battle)
      @groups = current_user.groups.page(params[:page]).per(19)
      @rival_groups = current_user.rival_groups.page(params[:page]).per(19)
      if @form.validate(params[:battles_select_group])
        @battle.challenger = current_user.groups.find(params[:battles_select_group][:group_object_id])
        render_wizard @form
      else
        @battle.errors[:base] << "Please select one of your groups."
        render_wizard
      end

    when :find_and_join_group
      @form = Battles::FindAndJoinGroupForm.new(@battle)
      if params[:q].present?
        @groups = Group.publicly_visible.where("name ILIKE ?" , "%#{params[:q]}%").where.not(id: current_user.groups.pluck(:id)).page(params[:page]).per(3)
      else
        @groups = Group.publicly_visible.where.not(id: current_user.groups.pluck(:id)).page(params[:page]).per(3)
      end

      if @form.validate(params[:battles_find_and_join_group]) 
        group_id = params[:battles_find_and_join_group][:group_id]
        # quick way to ensure the group they join is always public, a user could fill in the hidden field with integer.
        group = Group.publicly_visible.find(group_id)
        current_user.memberships.create(group: group, role: 'standard')
        @battle.challenger = group
        render_wizard @form
      else
        @battle.errors[:base] << "Please select a group by joining below."
        render_wizard
      end

    when :pick_this
      @form = Battles::PickThisForm.new(@battle)
      @photos = current_user.photos.page(params[:page]).per(19)
      @videos = current_user.videos.page(params[:page]).per(19)
      @documents = current_user.documents.page(params[:page]).per(19)

      if @form.validate(params[:battles_pick_this])
        selected_item = current_user.send(params[:battles_pick_this][:first_object_type]).find(params[:battles_pick_this][:first_object_id])
        @form.model.first_item = selected_item
        @form.model.first_item_name = @form.model.first_item.name
        render_wizard @form
      else
        @battle.errors[:base] << "Please select a first item."
        render_wizard
      end

    when :select_group_opponent
      @form = Battles::SelectGroupOpponentForm.new(@battle)
      filter = params[:items]

      if filter == 'rival_groups'
        @groups = current_user.rival_groups.page(params[:page]).per(10)
      else
        @groups = current_user.groups.page(params[:page]).per(19)
      end

      if @form.validate(params[:battles_select_group_opponent])
        @battle.opponent = Group.find(params[:battles_select_group_opponent][:group_object_id])
        @form.save
        redirect_to wizard_path(@next_step, {items: 'photos'})
      else
        @battle.errors[:base] << "Please select one of your groups."
        render_wizard
      end

    when :finalize_challenge
      @form = Battles::FinalizeChallengeForm.new(@battle)
      if @form.validate(params[:battles_finalize_challenge])
        @form.save
        @battle.challenge_opponent
        @battle.save #need to make sure the new state is saved

        # now auto add the rival group
        Rivalry.where(user: current_user, group: @battle.opponent).first_or_create

        # add a vote for the user
        @battle.votes.create(item: 'first', user: current_user)
        Battle.increment_counter(:first_item_vote_count, @battle.id)

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
        @form.model.opposing_user = current_user
        render_wizard @form.model
      else
        @battle.errors[:base] << "Please select an item."
        render_wizard
      end

    when :accept_challenge
      @form = Battles::AcceptChallengeForm.new(@battle)
      if @form.validate(params[:battles_accept_challenge])
        @battle.opposing_user = current_user
        @battle.challenge_accepted
        @battle.set_end_time(@battle.battle_length)
        
        # add a vote for the user
        @battle.votes.create(item: 'second', user: current_user)
        Battle.increment_counter(:second_item_vote_count, @battle.id)

        render_wizard @form
      else
        render_wizard
      end
    end
  end


  def finish_wizard_path
    # flash[:notice] = 'Your Battle Has Started!'
    battle_path(@battle)
  end

  private

    def load_battle
      @battle = Battle.unscoped.find(params[:battle_id])
      raise CustomExceptions::FlaggedError if @battle.visibility != 'visible'
      @next_step = next_step
    end

 end