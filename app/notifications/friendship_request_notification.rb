class FriendshipRequestNotification < ApplicationNotification
  attr_accessor :requestor

  def body
    <<-EOF.strip_heredoc
      #{link_to(requestor.full_name, user_url(requestor))} has sent you a request to become schoolies.
      #{link_to("Click Here to accept or decine", pending_friend_requests_user_url(recipient))}
    EOF
  end
end
