class AwardWinnersNotification < ApplicationNotification

  attr_accessor :battle, :recipient

  def body
    if battle.winner == 'draw'
      <<-EOF.strip_heredoc
        Your battle pass related to #{battle.challenger.name} Vs. #{battle.opponent.name} has been refunded because the battle ended in a draw.
        #{link_to('View Your Scrilla Ledger', user_scrilla_transfers_url(recipient))} for more details.
      EOF
    else
      <<-EOF.strip_heredoc
        Your award for supporting #{battle.winner.name} has been processed.
        #{link_to('View Your Scrilla Ledger', user_scrilla_transfers_url(recipient))} for more details.
      EOF
    end
  end
  
end
