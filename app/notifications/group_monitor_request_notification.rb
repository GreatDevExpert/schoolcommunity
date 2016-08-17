class GroupMonitorRequestNotification < ApplicationNotification
  attr_accessor :group, :requestor

  def body
    <<-EOF.strip_heredoc
      #{link_to(@requestor.full_name, user_url(@requestor))} has requested to become a monitor for the group #{@group.full_name}.  #{link_to("Click here to approve or deny.", monitors_group_url(@group))}
    EOF
  end
end
