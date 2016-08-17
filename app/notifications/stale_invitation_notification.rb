class StaleInvitationNotification < ApplicationNotification
  attr_accessor :target

  def body
    <<-EOF.strip_heredoc
      You have an unapproved invitation to join #{target.name}.  
      #{link_to("Click Here to join or decline", polymorphic_url(target))}.
    EOF
  end
end
