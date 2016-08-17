class StuffController < ApplicationController
  # usting this for the for remote ajax modals for battle item stuff
  layout false
  
  def photo
    @photo = Photo.find(params[:id])
    raise Pundit::NotAuthorizedError unless PhotoPolicy.new(current_user, @photo).show?
  end

  def video
    @video = Video.find(params[:id])
    raise Pundit::NotAuthorizedError unless VideoPolicy.new(current_user, @video).show?
  end

  def document
    @document = Document.find(params[:id])
    raise Pundit::NotAuthorizedError unless DocumentPolicy.new(current_user, @document).show?
  end


end