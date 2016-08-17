class Groups::VideosController < ApplicationController
  before_action :set_group

  def new
    @video = @group.videos.new
  end

  def create
    raise Pundit::NotAuthorizedError unless GroupPolicy.new(current_user, @group).new_post?
    @video = @group.videos.new(video_params)
    @video.user = current_user
    @video.pull_details

    if @video.save
      redirect_to videos_stuff_group_path(@group, filter: 'all'), notice: 'Video uploaded.'
    else
      render :new
    end
  end

  private

    def video_params
      params.require(:video).permit(:url, :year)
    end

    def set_group
      @group = Group.find(params[:group_id])
    end
end
