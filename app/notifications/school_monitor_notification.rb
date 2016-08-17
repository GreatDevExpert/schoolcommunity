class SchoolMonitorNotification < ApplicationNotification
  attr_accessor :school

  def body
    <<-EOF.strip_heredoc
      You have been promoted to a monitor of the school #{link_to(@school.full_name, url_for(@school))}
    EOF
  end
end
