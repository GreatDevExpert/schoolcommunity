class SchoolMonitorDeclinedNotification < ApplicationNotification
  attr_accessor :school

  def body
    <<-EOF.strip_heredoc
      Your request to become a monitor of the school #{link_to(@school.full_name, school_url(@school))} has been declined.
    EOF
  end
end
