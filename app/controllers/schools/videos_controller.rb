class Schools::VideosController < ApplicationController
  before_action :set_school
  before_action :set_selected, only: [:new, :create]

  def new
    @video = @school.videos.new
  end

  def create
    raise Pundit::NotAuthorizedError unless SchoolPolicy.new(current_user, @school).new_post?
    @video = @school.videos.new(video_params)
    @video.user = current_user
    @video.pull_details

    if @video.save
      redirect_to videos_stuff_school_path(@school, filter: 'all'), notice: 'Video uploaded.'
    else
      render :new
    end
  end

  private

    def video_params
      params.require(:video).permit(:url, :year)
    end

    def set_school
      @school = School.find(params[:school_id])
    end

    def set_selected
      fellowship = current_user.fellowships.find_by(school: @school, role: ['student', 'alumni', 'parent', 'faculty'])
      if fellowship
        @selected = fellowship.identifier
      end
    end
end
