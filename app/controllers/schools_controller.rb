class SchoolsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school, only: [:show, :edit, :update]
  before_action :set_fellowship, only: [:show]

  def index
    @schools = School.all
  end

  def show
    if current_user.super_admin?
      @activities = PublicActivity::Activity.where(recipient: @school).order("created_at DESC").page(params[:page]).per(20)
    elsif @fellowships.present?
      @activities = SchoolActivityQuery.new(@fellowships).activities.page(params[:page]).per(20)
    end
  end

  def new
    @school = School.new
    authorize @school
    @school.build_address
  end

  def create
    @school = School.new(school_params)
    authorize @school
    @school.fellowships.new(user: current_user, role: 'monitor', status: 'approved')
    @school.visibility = 'needs_approval'

    if @school.save
      save_avatar_to_school
      User.super_admins.each do |user|
        AdminMailer.school_needs_approval(@school, user).deliver_now
      end
      redirect_to schools_user_path(current_user), notice: "#{@school.name} has been created and is currently under review. We will alert you when your school has been verified."
    else
      render :new
    end
  end

  def edit
    # edit_school_params
    authorize @school
    @school.build_address if @school.address.blank?
  end

  def update
    authorize @school
    if @school.update_attributes(school_params)
      save_avatar_to_school
      redirect_to @school, notice: 'Successfully updated school.'
    else
      render :edit
    end
  end

  private

    def set_school
      if current_user.super_admin?
        @school = School.unscoped.find(params[:id])
      else
        @school = School.where(id: params[:id]).first
        if @school.blank?
          redirect_to root_url, notice: "School is not currently unavailable."
        end
      end
    end

    def set_fellowship
      @fellowships = current_user.fellowships.where(school: @school)
    end

    def school_params
      params.require(:school).permit(:name, :description, :avatar, :remote_avatar_url, :existing_photo_id, :address_attributes => [:line_one, :city, :state, :postal_code])
    end

    def save_avatar_to_school
      if school_params[:avatar]
        Photo.create(user: current_user, school: @school, year: DateTime.now, name: "School photo for #{@school.full_name}", file: school_params[:avatar])
      elsif school_params[:existing_photo_id].present?
        existing_photo = Photo.find(school_params[:existing_photo_id])
        duplicated_photo = existing_photo.dup
        duplicated_photo.school = @school
        CopyCarrierwaveFile::CopyFileService.new(existing_photo, duplicated_photo, :file).set_file
        duplicated_photo.save
      end
    end
end
