class ParentChildRelationshipApprovedNotification < ApplicationNotification
  attr_accessor :approving_user

  def body
    <<-EOF.strip_heredoc
      #{approving_user.full_name} has confirmed your relationship request.  #{link_to("Click Here", parent_child_relationships_url)} to view your relationships.
    EOF
  end
end
