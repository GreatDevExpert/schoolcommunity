class ScrillaRequestNotification < ApplicationNotification
  attr_accessor :requester, :scrilla_request

  def body
    <<-EOF.strip_heredoc
      #{link_to(requester.full_name, user_url(requester))} has requested #{scrilla_request.amount}.
      They included the following message: #{scrilla_request.message}
      #{link_to("Click Here", new_scrilla_transfer_url(scrilla_request: scrilla_request))} to send scrilla.
    EOF
  end
end
