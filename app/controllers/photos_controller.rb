class PhotosController < ApplicationController
  before_action :set_photo_objects, only: [:show, :destroy, :duplicate, :repost]
  before_action :set_commentable, only: :show

  def selector
    @photos = current_user.photos.page(params[:page]).per(10)
    if params[:q].present?
      @photos = @photos.where("name ILIKE ?", "%#{params[:q]}%")
    end

    render partial: 'photos/selector', layout: false
  end

  def new
    @photo = current_user.photos.new
  end

  def show
    authorize @photo
    set_meta_tags og: {
      title: @photo.name,
      type: "#{ENV['FACEBOOK_APP_NAMESPACE']}:photo",
      description: @comments.first.try(:content),
      image: @photo.file.large.url,
      url: url_for(@photo),
    }
  end

  def create
    @photo = current_user.photos.new(photo_params)
    validate_group_and_school_permissions

    @photo.visibility_type = photo_params[:identifier] == 'private' ? 'private' : 'public'

    if @photo.save
      if @photo.visibility_type == 'public'
        create_activity
        FacebookPost.new(user: current_user, action: 'add', photo: @photo).post
      end
      resolve_new_photo_redirect
    else
      render :new
    end
  end

  def destroy
    authorize @photo
    @photo.delete
    if @school.present?
      redirect_to photos_school_path(@school), notice: "Photo deleted."
    elsif @group.present?
      redirect_to photos_group_path(@group), notice: "Photo deleted."
    else
      redirect_to photos_stuff_user_path(current_user, filter: 'profile'), notice: 'Photo deleted.'
    end
  end

  def duplicate
    authorize @photo

    @duplicated_photo = @photo.dup
    @duplicated_photo.user = current_user
    @duplicated_photo.school = nil
    @duplicated_photo.group = nil
    CopyCarrierwaveFile::CopyFileService.new(@photo, @duplicated_photo, :file).set_file
    
    if @duplicated_photo.save
      redirect_to @duplicated_photo, notice: "Photo has been copied to your profile"
    else
      redirect_to :back, notice: "Unable to duplicate photo"
    end
  end

  def repost
    create_activity
    redirect_to :back, notice: 'Photo reposted to activity feed.'
  end

  private
    def photo_params
      params.require(:photo).permit(:name, :file, :file_cache, :existing_photo_id, :remote_file_url, :school_id, :group_id, :year, :identifier, :description)
    end

    def set_photo_objects
      if current_user_is_super_admin?
        @photo = Photo.unscoped.find(params[:id])
      else
        @photo = Photo.find(params[:id])
      end
      @school = @photo.school if @photo.school.present?
      @group = @photo.group if @photo.group.present?
    end

    def set_commentable
      @commentable = @photo
      @comment = Comment.new
      @comments = @commentable.comments
    end

    def create_activity
      @photo.create_activity key: "photo.create", owner: current_user, recipient: @photo.group || @photo.school, role: @photo.role
    end

    def validate_group_and_school_permissions
      if @photo.school && !SchoolPolicy.new(current_user, @photo.school).new_post?
        raise Pundit::NotAuthorizedError
      elsif @photo.group && !GroupPolicy.new(current_user, @photo.group).new_post?
        raise Pundit::NotAuthorizedError
      end
    end

    def resolve_new_photo_redirect
      if @photo.group.present?
        redirect_to photos_stuff_group_path(@photo.group, filter: 'all'), notice: 'Photo uploaded.'
      elsif @photo.school.present?
        redirect_to photos_stuff_school_path(@photo.school, filter: 'all'), notice: 'Photo uploaded.'
      else
        redirect_to photos_stuff_user_path(@photo.user, filter: 'profile'), notice: 'Photo uploaded.'
      end
    end
end
