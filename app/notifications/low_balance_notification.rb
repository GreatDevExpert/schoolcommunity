class LowBalanceNotification < ApplicationNotification

  def body
    <<-EOF.strip_heredoc
      Your account is almost out of scrilla.  You need scrilla to start battles.  #{link_to("Refill your scrilla account", user_scrilla_transfers_url(recipient))}
    EOF
  end
end
