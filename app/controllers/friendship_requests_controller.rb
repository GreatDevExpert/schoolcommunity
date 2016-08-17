class FriendshipRequestsController < ApplicationController
  def create
    @friend = User.find(params[:user_id])
    @friendship_request = FriendshipRequest.where(user: current_user, friend: @friend).first_or_initialize

    if @friendship_request.save
      flash[:info] = 'Your request has been sent'
    else
      flash[:error] = 'Unable to send friendship request to this user'
    end

    respond_to do |format|
      format.html { redirect_to user_path(@friend) }
      format.json { head :ok }
    end
  end

  def approve
    @friendship_request = FriendshipRequest.find(params[:id])

    if @friendship_request.approve!
      flash[:info] = 'Friendship request has been approved'
    else
      flash[:error] = 'Unable to approve friendship request'
    end

    respond_to do |format|
      format.html { redirect_to user_path(@friendship_request.user) }
      format.json { head :ok }
    end
  end

  def destroy
    @friendship_request = FriendshipRequest.find(params[:id])

    if @friendship_request.destroy
      flash[:info] = 'Friendship request has been declined'
    else
      flash[:error] = 'Error ocurred declining friendship request'
    end

    respond_to do |format|
      format.html { redirect_to pending_friend_requests_user_path(current_user) }
      format.json { head :ok }
    end
  end
end
