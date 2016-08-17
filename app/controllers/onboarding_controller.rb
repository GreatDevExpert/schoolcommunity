class OnboardingController < ApplicationController
  include Wicked::Wizard
  steps :confirm_profile, :find_a_school, :set_year, :find_friends, :invite_friends, :mission_statement
  before_action :ensure_not_active

  def show
    @user = current_user
    @step = step
    case @step
    when :confirm_profile
      skip_step unless @user.state == 'confirm_profile'
      # have to shove render_wizard in each case statement so I can redirect on the finish step and not get an error about redirecting more than once
      render_wizard
    when :find_a_school
      skip_step unless @user.state == 'find_a_school'
      # skip_step unless @user.schools.size == 0
      search_schools
      render_wizard
    when :set_year
      skip_step unless @user.state == 'find_a_school'
      @role = params[:role]
      if params[:school_id].present?
        @school = School.find(params[:school_id])
      end
      @new_fellowhsip  = @user.fellowships.build(school: @school, role: @role)
      render_wizard
    when :find_friends
      skip_step if current_user.friendship_recommendations.blank?
      # to support the skip step after a user already add a school
      if params[:find_friends] == 'true' && @user.state != 'find_friends'
        @user.update_attribute(:state, 'find_friends')
      end
      skip_step unless @user.state == 'find_friends'

      @query = params[:query]
      if @query.present?
        current_user_id = current_user.id
        @search = Sunspot.search(FriendshipRecommendation) do
          all_of do
            with(:user_id, current_user_id)
          end
          fulltext params[:query] 
          order_by(:score, :desc)
          paginate :page => params[:page]
        end
        @recommendations = @search.results
      else
        @recommendations = current_user.friendship_recommendations.page(params[:page]).per(20)
      end
      render_wizard
    when :invite_friends
      @friends = FacebookGraph.new(current_user.facebook_token).pull_invitable_friends
      skip_step if @friends.blank?

      render_wizard
    when :mission_statement
      @user.update_attribute(:state, 'mission_statement') unless @user.state == 'mission_statement' || @user.state == 'active'

      render_wizard
    end
  end

  def update
    @user = current_user
    case step
    when :confirm_profile
      @user.assign_attributes(user_params)
      @user.state = 'find_a_school'

      registration = UserRegistration.new(@user)
      registration.facebook_request_ids = cookies[:facebook_request_ids] if cookies[:facebook_request_ids]
      if @user.valid?
        registration.complete_registration 
      end
      render_wizard @user

    when :find_a_school
      # just a place holder page, never submit from here

    when :set_year
      ensure_fellowship_roles_allowed
      @school = School.find(params[:user][:fellowship][:school_id])
      @new_fellowhsip = @user.fellowships.build(new_fellowship_params)
      if @new_fellowhsip.valid?  && params[:commit] == 'Add Another School'
        @user.save
        redirect_to(wizard_path :find_a_school)
      elsif @new_fellowhsip.valid?
        @user.state = 'find_friends'
        render_wizard @user
      else
        render_wizard @user
      end

    when :find_friends
      render_wizard @user

    when :invite_friends
      render_wizard @user

    when :mission_statement
      @user.update_attribute(:state, 'active')
      redirect_to root_url, notice: 'Account Activated. Welcome to Myschool!'
    end

  end

  private

    def search_schools
      @query = params[:school_query]
      user_city = @user.city_description
      user_postal_code = @user.postal_code
      current_user_school_ids = @user.schools.pluck(:id)

      if @query.blank?
        @search = Sunspot.search(School) do
          all_of do
            without(:id, current_user_school_ids)
          end
          fulltext user_city do
            boost_fields full_address: 8.0 #for categories, badges
          end

        end
      else
        @search = Sunspot.search(School) do
          fulltext params[:school_query] do
            boost_fields name: 8.0 #for categories, badges
          end
          order_by(:score, :desc)
          paginate :page => params[:page]
        end
      end

      if @search.results.present?
        @schools = @search.results
      else
        @schools = School.page(params[:page]).per(25)
      end
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :avatar, :remote_avatar_url, :email, :birthday, :postal_code, :city_description, fellowships_attributes: [:role, :id, :graduation_date, :status])
    end

    def new_fellowship_params
      params.require(:user).require(:fellowship).permit(:role, :id, :graduation_date, :status, :school_id).merge(status: 'approved')
    end

    def ensure_not_active
      raise Pundit::NotAuthorizedError if current_user.state == 'active'
    end

    def ensure_fellowship_roles_allowed
      requsted_role = params[:user][:fellowship][:role]
      raise Pundit::NotAuthorizedError unless ['student', 'alumni'].include?(requsted_role)
    end

end
