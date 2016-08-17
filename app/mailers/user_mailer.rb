class UserMailer < ActionMailer::Base
  default from: "MySchool <info@myschool411.com>"

  def school_approved(school)
    @school = school
    @user = @school.monitors.first
    return if @user.blank?

    mail to: @user.email, bcc: 'support@myschool411.com', subject: "#{@school.name} - Has Been Approved"
  end

  def school_declined(school)
    @school = school
    @user = @school.monitors.first
    return if @user.blank?

    mail to: @user.email, bcc: 'support@myschool411.com', subject: "#{@school.name} - Declined"
  end

end