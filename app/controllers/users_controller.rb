class UsersController < ApplicationController
  before_action :load_user, only: [:show, :suspend_account, :unsuspend_account]

  def show
    authorize @user
    @activities = UserActivityQuery.new(@user).activities.page(params[:page]).per(20)
  end

  def cancel_my_account
    current_user.update_attribute(:state, 'canceled')
    sign_out(current_user)
    redirect_to root_url, notice: 'Your account has been canceled.'
  end

  def suspend_account
    authorize @user
    confirm_all_user_open_flags
    remove_related_objects
    @user.update_attribute(:state, 'suspended')
    reindex_realted_objects
    # sign_out(@user)
    redirect_to user_path(@user)
  end

  def unsuspend_account
    authorize @user
    @user.update_attributes(state: 'active', visibility: 'visible')
    # sign_out(@user)
    reindex_realted_objects
    redirect_to user_path(@user), notice: 'Account is now active.'
  end

  private

    def confirm_all_user_open_flags
      @user.flags_offenses.in_open_status.each do |f|
       f.update_attributes(action_taken: 'confirmed', resolving_user: current_user)
      end
    end

    def remove_related_objects
      FriendshipRecommendation.where(recommended_friend: @user).destroy_all
      FriendshipRecommendation.where(user: @user).destroy_all
      FriendshipRequest.where(user: @user).destroy_all
      FriendshipRequest.where(friend: @user).destroy_all
    end

    def reindex_realted_objects
      #need to do this so we show the members of a school correctly correctly
      @user.fellowships.each do |fellowship|
        Reindex.perform_later(fellowship)
      end
      @user.memberships.each do |membrship|
        Reindex.perform_later(membrship)
      end
    end

    def load_user
      if current_user && current_user.super_admin?
        @user = User.unscoped.find(params[:id])
      else
        @user = User.where(id: params[:id]).first
        if @user.blank?
          redirect_to root_url, notice: "This user's account is not currently available."
        end
      end
    end

end
