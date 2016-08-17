class MessageNotification < ApplicationNotification
  attr_accessor :sender, :recipient, :message

  def body
    <<-EOF.strip_heredoc
      #{link_to(sender.full_name, user_url(sender))} has sent you a note:
      <div class="panel callout">
        #{message}
      </div>
      #{link_to("Click here to reply", new_user_message_url(sender))}
    EOF
  end
end
