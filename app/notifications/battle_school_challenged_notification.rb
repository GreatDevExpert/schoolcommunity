class BattleSchoolChallengedNotification < ApplicationNotification

  attr_accessor :battle

  def body
    <<-EOF.strip_heredoc
      #{link_to(battle.owner.full_name, user_url(battle.owner))} has challenged #{battle.opponent.name} to a #{battle.human_battle_kind} Battle titled #{link_to(battle.description, battle_url(battle))}.
      #{link_to('Buy Your Battle Pass', battle_url(battle))}
    EOF
  end

end
