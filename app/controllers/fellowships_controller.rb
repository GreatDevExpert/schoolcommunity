class FellowshipsController < ApplicationController
  before_action :set_fellowship, only: [:become_alumni, :approve_become_alumni, :approve_monitor, :decline_monitor, :destroy, :edit_student, :edit_alumni, :update]
  before_action :set_school_by_id, only: [:new_monitor_request, :step_down_as_monitor]
  before_action :set_school_by_school_id, only: [:new_student, :new_alumni, :new_faculty, :new_parent, :become_alumni, :approve_become_alumni, :approve_monitor, :destroy, :edit_student, :edit_alumni, :update]

  def new_student
    graduation_date_estimator = GraduationDateEstimator.new(user: current_user, school: @school, fellowship_type: 'student')
    @fellowship = Fellowship.new(user: current_user, graduation_date: graduation_date_estimator.graduation_date, school: @school, role: 'student', status: 'approved')
  end

  def new_alumni
    graduation_date_estimator = GraduationDateEstimator.new(user: current_user, school: @school, fellowship_type: 'alumni')
    @fellowship = Fellowship.new(user: current_user, graduation_date: graduation_date_estimator.graduation_date, school: @school, role: 'alumni', status: 'approved')
  end

  def new_faculty
    @fellowship = Fellowship.new(user: current_user, school: @school, role: 'faculty', status: 'approved')
  end

  def new_parent
    @relationship = ParentChildRelationship.new(parent: current_user, requesting_user: current_user)
    @query = params[:q]

    all_relationships = current_user.child_relationships
    active_children_ids = current_user.child_relationships.where(aasm_state: 'approved').pluck(:child_id)
    inactive_children_ids = current_user.child_relationships.where(aasm_state: 'pending_approval').pluck(:child_id)

    active_children = User.where(id: active_children_ids)
    inactive_children = User.where(id: inactive_children_ids)

    all_students = @school.students.where.not(fellowships: {user: current_user})

    @existing_children = all_students.where(id: active_children_ids)
    @pending_children = all_students.where(id: inactive_children_ids)
    @students = all_students.where.not(id: active_children_ids).where.not(id: inactive_children_ids)
    if @query
      @students = @students.where("first_name ILIKE ? OR last_name ILIKE ?", "%#{@query}%", "%#{@query}%")
    end
    @students = @students.page(params[:page]).per(20)
  end

  def edit_student
  end

  def edit_alumni
  end

  def update
    if @fellowship.update_attributes(fellowship_params)
      redirect_to @school, notice: "Your changes have been saved"
    else
      redirect_to @school, notice: "Unable to save your changes"
    end
  end


  def become_alumni
    authorize @fellowship
  end

  def approve_become_alumni
    authorize @fellowship

    @fellowship.become_alumni!
    redirect_to @school, notice: "You are now an alumni"
  end

  def create
    @fellowship = current_user.fellowships.new(fellowship_params)
    @school = @fellowship.school
    if ['student', 'alumni', 'faculty'].include?(@fellowship.role)
      # auto approve status
      @fellowship.status = 'approved'
    end

    if @fellowship.save
      @school.create_activity key: 'school.new_member', owner: @fellowship.user, recipient: @school, role: @fellowship.role
      redirect_to @school, notice: "You are now a member of this school"
    else
      redirect_to :back, notice: @fellowship.errors.full_messages.first
    end
  end

  def new_monitor_request
    authorize @school, :new_monitor_request?
    @fellowship = Fellowship.where(user: current_user, school: @school, role: 'monitor').first_or_initialize(user: current_user, school: @school, role: 'monitor')
    # @fellowship = current_user.fellowships.new(school: @school, role: 'monitor', status: 'pending')

    if @school.monitors.count == 0
      if @fellowship.update(status: 'approved')
        redirect_to school_path(@school), notice: "You have been promoted to monitor of this school"
      else
        redirect_to school_path(@school), alert: "An error occurred processing your monitor request"
      end
    elsif @fellowship.update(status: 'pending')
      @school.monitors.each do |monitor|
        SchoolMonitorRequestNotification.new(recipient: monitor, requestor: current_user, school: @school).notify
      end
      redirect_to monitors_school_path(@school), notice: "Monitor request request has been received."
    else
      redirect_to monitors_school_path(@school), alert: "Sorry, you can't become a monitor of #{@school.name}."
    end
  end

  def step_down_as_monitor
    @fellowships = current_user.fellowships.where(school: @school, role: 'monitor')

    @fellowships.destroy_all
    redirect_to monitors_school_path(@school), notice: "You are no longer a monitor of #{@school.name}."
  end

  def approve_monitor
    authorize @fellowship

    if @fellowship.update_attribute(:status, 'approved')
      SchoolMonitorNotification.new(recipient: @fellowship.user, school: @school).notify
      redirect_to monitors_school_path(@school), notice: "#{@fellowship.user.full_name} is now a monitor of #{@school.name}."
    else
      redirect_to monitors_school_path(@school), alert: "Could not approve #{@fellowship.user.full_name} as a monitor #{@school.name}."
    end
  end

  def decline_monitor
    authorize @fellowship, :approve_monitor?
    @school = @fellowship.school

    if @fellowship.destroy
      SchoolMonitorDeclinedNotification.new(recipient: @fellowship.user, school: @school).notify
      redirect_to monitors_school_path(@school), notice: "The request to be a monitor has been declined"
    else
      redirect_to monitors_school_path(@school), alert: "An error occurred declining this membership"
    end
  end

  def destroy
    authorize @fellowship
    role = @fellowship.role
    user = @fellowship.user
    if @fellowship.destroy
      redirect_to @school, notice: "You are no longer a member of #{@school.full_name}"
      @school.create_activity key: 'school.member_left', owner: user, recipient: @school, role: role
    else
      redirect_to @school, notice: "Unable to remove school"
    end
  end

  private 
    def set_fellowship
      @fellowship = Fellowship.find(params[:id])
    end

    def set_school_by_id
      @school = School.find(params[:id])
    end

    def set_school_by_school_id
      @school = School.find(params[:school_id])
    end

    def fellowship_params
      params.require(:fellowship).permit(:school_id, :graduation_date, :role)
    end

end
