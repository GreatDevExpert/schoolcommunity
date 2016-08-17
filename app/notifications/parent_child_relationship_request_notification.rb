class ParentChildRelationshipRequestNotification < ApplicationNotification
  attr_accessor :requestor

  def body
    <<-EOF.strip_heredoc
      You have received a request from #{requestor.full_name} to confirm your relationship.  #{link_to("Click Here", parent_child_relationships_url)} to accept or refuse.
    EOF
  end
end
