class GroupMonitorNotification < ApplicationNotification
  attr_accessor :group

  def body
    <<-EOF.strip_heredoc
      You have been promoted to a monitor of the group #{link_to(@group.full_name, url_for(@group))}
    EOF
  end
end
