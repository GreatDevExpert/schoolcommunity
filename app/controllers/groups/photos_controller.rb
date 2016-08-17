class Groups::PhotosController < ApplicationController
  before_action :set_group

  def new
    @photo = @group.photos.new
    @comment = @photo.comments.build
  end

  def create
    raise Pundit::NotAuthorizedError unless GroupPolicy.new(current_user, @group).new_post?
    @photo = @group.photos.new(photo_params)
    @photo.user = current_user
    @comment = @photo.comments.build(first_comment_params)

    if @photo.save
      redirect_to photos_stuff_group_path(@group, filter: 'all'), notice: 'Photo uploaded.'
    else
      render :new
    end
  end

  private

    def photo_params
      params.require(:photo).permit(:file, :name, :remote_file_url, :description, :year)
    end

    def first_comment_params
      params.require(:photo).require(:comment).permit(:content).merge(user_id: current_user.id)
    end

    def set_group
      @group = Group.find(params[:group_id])
    end
end
