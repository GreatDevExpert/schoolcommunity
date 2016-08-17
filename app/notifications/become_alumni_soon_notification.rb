class BecomeAlumniSoonNotification < ApplicationNotification
  attr_accessor :fellowship

  def body
    <<-EOF.strip_heredoc
    Your graduation date for #{fellowship.school.full_name} is set to pass on #{fellowship.graduation_date}.  You will automatically be made an alumni of this school.  If this graduation date has changed, please update your school's graduation date in MySchool.
    EOF
  end
end
