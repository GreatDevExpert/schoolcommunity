class FriendshipController < ApplicationController
  def destroy
    @friend = User.find(params[:id])
    Friendship.remove_friendship(user1: current_user, user2: @friend)
    redirect_to user_path(@friend), notice: "You are no longer schoolies"
  end
end
