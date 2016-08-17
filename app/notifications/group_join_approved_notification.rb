class GroupJoinApprovedNotification < ApplicationNotification
  attr_accessor :group

  def body
    <<-EOF.strip_heredoc
      Your membership to the group #{link_to(@group.full_name, group_url(@group))} has been approved.
    EOF
  end
end
