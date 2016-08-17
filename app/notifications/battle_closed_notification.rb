class BattleClosedNotification < ApplicationNotification

  attr_accessor :battle

  def body
    if battle.owner == recipient
      <<-EOF.strip_heredoc
        Your #{battle.human_battle_kind} Battle titled #{battle.description} is over.
        #{link_to('View results', battle_url(battle))}.
      EOF
    else
      <<-EOF.strip_heredoc
         #{link_to(battle.owner.first_name_possessive, user_url(battle.owner))} #{battle.human_battle_kind} Battle titled #{battle.description} is over.
        #{link_to('View results', battle_url(battle))}.
      EOF
    end
  end
end
