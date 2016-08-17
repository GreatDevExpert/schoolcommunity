class GroupMonitorDeclinedNotification < ApplicationNotification
  attr_accessor :group

  def body
    <<-EOF.strip_heredoc
      Your request to become a monitor of the group #{link_to(@group.full_name, group_url(@group))} has been declined.
    EOF
  end
end
