class GroupJoinRequestNotification < ApplicationNotification
  attr_accessor :group, :requestor

  def body
    <<-EOF.strip_heredoc
      #{link_to(@requestor.full_name, user_url(@requestor))} has requested to join the group #{@group.full_name}.  #{link_to("Click here to approve or deny.", members_group_url(@group, role: 'pending'))}
    EOF
  end
end
