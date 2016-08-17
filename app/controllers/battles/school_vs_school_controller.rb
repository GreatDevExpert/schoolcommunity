class Battles::SchoolVsSchoolController < ApplicationController
  include Wicked::Wizard
  before_action :load_battle

  steps :select_school, :select_school_opponent, :select_sport, :finalize_challenge, :add_scores
  
def show
    authorize @battle
    case step

    when :select_school
      @form = Battles::SelectSchoolForm.new(@battle)
      @schools = current_user.schools.page(params[:page]).per(19)
      @rival_schools = current_user.rival_schools.page(params[:page]).per(19)

    when :select_school_opponent
      @form = Battles::SelectSchoolOpponentForm.new(@battle)
      filter = params[:items]
      if params[:q].present?
        if filter == 'rival_schools'
          @schools = current_user.rival_schools.where("name ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(19)
        else
          @schools = School.where("name ILIKE ?" , "%#{params[:q]}%").page(params[:page]).per(19)
        end
      else
        if filter == 'rival_schools'
          @schools = current_user.rival_schools.page(params[:page]).per(19)
        else
          @schools = School.page(params[:page]).per(19)
        end
      end

    when :select_sport
      @form = Battles::SelectSportForm.new(@battle)
      @sports = SPORT_OPTIONS

    when :finalize_challenge
      @form = Battles::FinalizeGameTimeForm.new(@battle)
      @set_start_date = '12:00pm'
    when :add_scores
      skip_step if @battle.aasm_state != 'needs_scores'
      @form = Battles::AddScoresForm.new(@battle)
    end

    render_wizard
  end

  def update
    authorize @battle
    case step

    when :select_school
      @form = Battles::SelectSchoolForm.new(@battle)
      @schools = current_user.schools.page(params[:page]).per(19)
      @rival_schools = current_user.rival_schools.page(params[:page]).per(19)
      if @form.validate(params[:battles_select_school])
        @battle.challenger = current_user.schools.find(params[:battles_select_school][:school_object_id])
        @form.save
        if current_user.rival_schools.present?
          redirect_to wizard_path(@next_step, {items: 'rival_schools'})
        else
          redirect_to wizard_path(@next_step, {items: 'schools'})
        end
      else
        @battle.errors[:base] << "Please select one of your schools."
        render_wizard
      end

    when :select_school_opponent
      @form = Battles::SelectSchoolOpponentForm.new(@battle)
      filter = params[:items]

      if filter == 'rival_schools'
        @rival_schools = current_user.rival_schools.page(params[:page]).per(19)
      else
        @schools = School.all.page(params[:page]).per(19)
      end

      if @form.validate(params[:battles_select_school_opponent])
        @battle.opponent = School.find(params[:battles_select_school_opponent][:school_object_id])
        render_wizard @form
      else
        @battle.errors[:base] << "Please select a school."
        render_wizard
      end

    when :select_sport
      @form = Battles::SelectSportForm.new(@battle)
      @sports = SPORT_OPTIONS
      
      if @form.validate(params[:battles_select_sport])

        render_wizard @form
        @battle.update_attribute(:description, "#{@battle.sport_category} #{@battle.team_level} #{@battle.sport_name}: #{@battle.challenger.name} VS #{@battle.opponent.name}")
      else
        if params[:battles_select_sport][:sport_category].blank?
          @battle.errors[:base] << "Please select a Men's Women's Or Co-Ed."
        end
        render_wizard
      end

    when :finalize_challenge
      @form = Battles::FinalizeGameTimeForm.new(@battle)
      @set_start_date = params[:battles_finalize_game_time][:start_time]

      if @form.validate(params[:battles_finalize_game_time])
        @form.save # save form object data
        @battle.set_game_time
        @battle.set_end_time(@battle.battle_length)
        @battle.start_pregame
        @battle.save # save form ends_at and new aasm_state
        
        # now auto add the rival group
        Rivalry.where(user: current_user, school: @battle.opponent).first_or_create
        redirect_to battle_path(@battle)
      else
        render_wizard
      end

    when :add_scores
      @form = Battles::AddScoresForm.new(@battle)
      if @form.validate(params[:battles_add_scores])
        @form.save # save form object data
        @battle.post_game
        @battle.save # save form ends_at and new aasm_state
        redirect_to battle_path(@battle)
      else
        @battle.errors[:base] << "Please select the logo of the winner or draw."
        render_wizard
      end
    end
  end

  def finish_wizard_path
    # flash[:notice] = nil
    battle_path(@battle)
  end

  private

    def load_battle
      @battle = Battle.unscoped.find(params[:battle_id])
      raise CustomExceptions::FlaggedError if @battle.visibility != 'visible'
      @next_step = next_step
    end

end