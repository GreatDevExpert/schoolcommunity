class FacebookRequestsController < ApplicationController
  def create
    facebook_request_id = params[:facebook_request_id]
    facebook_request = FacebookRequest.create(request_id: facebook_request_id, user: current_user, request_type: 'invitation')

    respond_to do |format|
      format.html { redirect_to invite_friends_path }
      format.json { head :ok }
    end
  end
end
