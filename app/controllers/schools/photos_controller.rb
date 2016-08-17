class Schools::PhotosController < ApplicationController
  before_action :set_school
  before_action :set_selected, only: [:new, :create]

  def new
    @photo = @school.photos.new
    @comment = @photo.comments.build
  end

  def create
    raise Pundit::NotAuthorizedError unless SchoolPolicy.new(current_user, @school).new_post?
    @photo = @school.photos.new(photo_params)
    @photo.user = current_user
    @comment = @photo.comments.build(first_comment_params)

    if @photo.save
      redirect_to photos_stuff_school_path(@school, filter: 'all'), notice: 'Photo uploaded.'
    else
      render :new
    end
  end

  private

    def photo_params
      params.require(:photo).permit(:file, :name, :remote_file_url, :description, :year)
    end

    def set_school
      @school = School.find(params[:school_id])
    end
    
    def first_comment_params
      params.require(:photo).require(:comment).permit(:content).merge(user_id: current_user.id)
    end

    def set_selected
      fellowship = current_user.fellowships.find_by(school: @school, role: ['student', 'alumni', 'parent', 'faculty'])
      if fellowship
        @selected = fellowship.identifier
      end
    end

end
