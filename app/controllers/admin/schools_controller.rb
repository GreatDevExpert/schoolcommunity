class Admin::SchoolsController < Admin::BaseController
  before_action :set_school, only: [:show, :approve, :decline]

  def index
    @schools = School.unscoped.where(visibility: 'needs_approval')
  end

  def approve
    @school.update_attribute(:visibility, 'visible')
    UserMailer.school_approved(@school).deliver_now
    redirect_to admin_schools_path, notice: 'School Approved!'
  end

  def decline
    if @school.update_attributes(visibility: 'hidden', declined_comments: params[:school][:declined_comments])
      UserMailer.school_declined(@school).deliver_now
      redirect_to admin_schools_path, notice: 'School Declined!'
    else
      redirect_to admin_schools_path, alert: "Could not decline school! #{@school.errors}"
    end
  end

  private
    def set_school
      @school = School.unscoped.find(params[:school_id])
    end

end