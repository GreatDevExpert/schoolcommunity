class GroupsController < ApplicationController
  before_action :set_group, only: [:show, :edit, :update, :destroy, :confirm_destroy]

  def show
    authorize @group
    @activities = GroupActivityQuery.new(@group).activities.page(params[:page]).per(20)
  end

  def new
    @group = Group.new(visibility_type: 'public')
    authorize @group
  end

  def create
    @group = Group.new(create_group_params)
    authorize @group

    if @group.save
      create_group_membership
      save_avatar_to_group

      if @group.visibility_type == 'public' || @group.visibility_type == 'moderated'
        @group.create_activity key: "group.create", owner: current_user, trackable: @group, recipient: @group
      end
      
      redirect_to @group, notice: 'Welcome to your new group!'
    else
      render :new
    end
  end

  def edit
  end

  def update
    authorize @group
    if @group.update(update_group_params)
      save_avatar_to_group
      redirect_to @group, notice: 'Successfully updated group.'
    else
      render :edit
    end
  end

  def confirm_destroy
  end

  def destroy
    authorize @group
    if @group.update(visibility: 'hidden')
      redirect_to root_path, notice: "#{@group.full_name} has been deleted"
    else
      redirect_to @group, notice: "An error occurred updating your group"
    end
  end

  private
    def update_group_params
      params.require(:group).permit(:name, :description, :school_id, :avatar, :remote_avatar_url, :existing_photo_id)
    end

    def create_group_params
      params.require(:group).permit(:name, :description, :visibility_type, :school_id, :avatar, :remote_avatar_url, :existing_photo_id)
    end

    def set_group
      if current_user && current_user.super_admin?
        @group = Group.unscoped.find(params[:id])
      else
        @group = Group.where(id: params[:id]).first
        if @group.blank?
          redirect_to root_url, notice: 'No such group'
        end
      end
    end

    def create_group_membership
      Membership.create(user: current_user, role: 'monitor', group: @group, status: 'approved')
    end

    def save_avatar_to_group
      if create_group_params[:avatar]
        Photo.create(user: current_user, group: @group, year: DateTime.now, name: "Group photo for #{@group.full_name}", file: create_group_params[:avatar])
      elsif create_group_params[:existing_photo_id].present?
        existing_photo = Photo.find(create_group_params[:existing_photo_id])
        duplicated_photo = existing_photo.dup
        duplicated_photo.group = @group
        CopyCarrierwaveFile::CopyFileService.new(existing_photo, duplicated_photo, :file).set_file
        duplicated_photo.save
      end
    end

end
