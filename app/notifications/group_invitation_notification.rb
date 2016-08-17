class GroupInvitationNotification < ApplicationNotification
  attr_accessor :sender, :message, :group

  def body
    ActionController::Base.helpers.safe_join [body_fragment, message_fragment]
  end

  private

  def body_fragment
    body = <<-EOF.strip_heredoc
      #{link_to(sender.full_name, user_url(sender))} has invited you to join the group #{group.name}.
      #{link_to("Click Here to join or decline.", polymorphic_url(group))}
    EOF
    body.html_safe
  end

  def message_fragment
    if message.present?
      ActionController::Base.helpers.safe_join [
        "The following message was included:".html_safe,
        "<div class='panel callout'>".html_safe,
        message,
        "</div>".html_safe
      ]
    else
      ''
    end
  end
end
