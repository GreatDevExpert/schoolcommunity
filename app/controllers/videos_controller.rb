class VideosController < ApplicationController
  before_action :set_video_objects, only: [:show, :destroy, :duplicate, :repost]
  before_action :set_commentable, only: :show

  def selector
    @videos = current_user.videos.page(params[:page]).per(10)
    if params[:q].present?
      @videos = @videos.where("title ILIKE ?", "%#{params[:q]}%")
    end

    render partial: 'videos/selector', layout: false
  end

  def new
    @video = current_user.videos.build
    authorize @video
  end

  def show
    authorize @video
    @school = @video.school if @video.school.present?
    @group = @video.group if @video.group.present?
    set_meta_tags og: {
      title: @video.title,
      type: "video.other",
      description: @video.description,
      image: @video.thumbnail_large,
      url: url_for(@video),
    }
  end

  def create
    @video = current_user.videos.new(video_params)
    authorize @video
    validate_group_and_school_permissions

    @video.visibility_type = video_params[:identifier] == 'private' ? 'private' : 'public'

    @video.pull_details

    if @video.save
      if @video.visibility_type == 'public'
        create_activity
        FacebookPost.new(user: current_user, action: 'add', other: @video).post
      end
      resolve_new_video_redirect
    else
      render :new
    end
  end

  def destroy
    authorize @video
    @video.delete
    
    if @school.present?
      redirect_to videos_stuff_school_path(@school), notice: "Video deleted."
    elsif @group.present?
      redirect_to videos_stuff_group_path(@group), notice: "Video deleted."
    else
      redirect_to videos_stuff_user_path(current_user, filter: 'profile'), notice: 'Video deleted.'
    end
  end

  def duplicate
    authorize @video

    @duplicated_video = @video.dup
    @duplicated_video.user = current_user
    @duplicated_video.school = nil
    @duplicated_video.group = nil

    if @duplicated_video.save
      redirect_to @duplicated_video, notice: "Video has been copied to your profile"
    else
      redirect_to :back, notice: "Unable to duplicate video"
    end

  end

  def repost
    create_activity
    redirect_to :back, notice: 'Video reposted to activity feed.'
  end

  private

    def video_params
      params.require(:video).permit(:url, :title, :school_id, :group_id, :year, :identifier, :existing_video_id)
    end
    
    def set_video_objects
      @video = Video.find(params[:id])
      @school = @video.school if @video.school.present?
      @group = @video.group if @video.group.present?
    end

    def set_commentable
      @commentable = @video
      @comment = Comment.new
      @comments = @commentable.comments
    end

    def create_activity
      @video.create_activity key: "video.create", owner: current_user, recipient: @video.group || @video.school, role: @video.role
    end

    def validate_group_and_school_permissions
      if @video.school && !SchoolPolicy.new(current_user, @video.school).new_post?
        raise Pundit::NotAuthorizedError
      elsif @video.group && !GroupPolicy.new(current_user, @video.group).new_post?
        raise Pundit::NotAuthorizedError
      end
    end

    def resolve_new_video_redirect
      if @video.group.present?
        redirect_to videos_stuff_group_path(@video.group, filter: 'all'), notice: 'Video uploaded.'
      elsif @video.school.present?
        redirect_to videos_stuff_school_path(@video.school, filter: 'all'), notice: 'Video uploaded.'
      else
        redirect_to videos_stuff_user_path(@video.user, filter: 'profile'), notice: 'Video uploaded.'
      end
    end

end
