class SchoolMonitorRequestNotification < ApplicationNotification
  attr_accessor :school, :requestor

  def body
    <<-EOF.strip_heredoc
      #{link_to(@requestor.full_name, user_url(@requestor))} has requested to become a monitor for the school #{@school.full_name}.  #{link_to("Click here to approve or deny.", monitors_school_url(@school))}
    EOF
  end
end
