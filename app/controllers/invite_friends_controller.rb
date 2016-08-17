class InviteFriendsController < ApplicationController
  def index
    @friends = FacebookGraph.new(current_user.facebook_token).pull_invitable_friends
  end
end
