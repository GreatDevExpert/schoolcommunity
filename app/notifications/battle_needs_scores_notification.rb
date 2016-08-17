class BattleNeedsScoresNotification < ApplicationNotification

  attr_accessor :battle

  def body
    <<-EOF.strip_heredoc
      Your #{battle.human_battle_kind} Battle titled #{battle.description} is over. It's time to add add the results and let eveyone know who won.
      #{link_to('Select Winner Now', battle_school_vs_school_url(@battle, 'add_scores'))}.
    EOF
  end
end
