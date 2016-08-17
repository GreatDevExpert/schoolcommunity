class FriendshipApprovedNotification < ApplicationNotification
  attr_accessor :friend

  def body
    <<-EOF.strip_heredoc
      #{link_to(friend.full_name, user_url(friend))} has approved your schoolie request.
      #{link_to('Click Here', friends_user_url(recipient))} to visit your schoolies list.
    EOF
  end
end
