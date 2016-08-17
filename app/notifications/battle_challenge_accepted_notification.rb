class BattleChallengeAcceptedNotification < ApplicationNotification
  attr_accessor :battle

  def body
    <<-EOF.strip_heredoc
      #{link_to(battle.opposing_user.full_name, user_url(battle.opposing_user))} has accepted your #{battle.human_battle_kind} Battle challenge.
      #{link_to(battle.description, battle_url(battle))}.
    EOF
  end

end
