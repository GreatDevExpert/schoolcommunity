class AdminMailer < ActionMailer::Base
  default from: '"Myschool" <no-reply@myschool411.com>'

  def error_alert(error_message)
    @error_message = error_message

    mail to: ['juddl333@gmail.com', 'matt@goatcher.me'], subject: 'MySchool Error Alert'
  end

  def stale_flag_alert(flag, user)
    @flag = flag
    @reporting_user = @flag.reporting_user
    @offending_user = @flag.offending_user

    mail to: user.email, subject: "Stale Flag Alert - Flag ID: #{@flag.id}"
  end

  def flag_for_closed_school_vs_school(flag, recipient)
    @flag = flag
    @recipient = recipient
    @reporting_user = @flag.reporting_user
    @offending_user = @flag.offending_user

    mail to: @recipient.email, subject: "Schools Vs School Flag Alert - Flag ID: #{@flag.id}"
  end


  def school_needs_approval(school, recipient)
    @school = school
    @recipient = recipient

    mail to: @recipient.email, subject: "Approval Needed - New School Added: #{@school.name}"
  end

end
