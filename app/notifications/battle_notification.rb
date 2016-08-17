class BattleNotification < ApplicationNotification
  attr_accessor :battle

  def body
    if battle.kind == 'me_vs_you'
      <<-EOF.strip_heredoc
        #{link_to(battle.owner.full_name, user_url(battle.owner))} and #{link_to(battle.opposing_user.full_name, user_url(battle.opposing_user))} have started a #{battle.human_battle_kind} Battle titled 
        #{link_to(battle.description, battle_url(battle))}.
      EOF
    elsif battle.kind == 'group_vs_group'
      <<-EOF.strip_heredoc
        #{link_to(battle.challenger.name, user_url(battle.challenger))} and #{link_to(battle.opponent.name, user_url(battle.opponent))} have started a #{battle.human_battle_kind} Battle titled 
        #{link_to(battle.description, battle_url(battle))}.
      EOF
    elsif battle.kind == 'school_vs_school'
      <<-EOF.strip_heredoc
        #{link_to(battle.owner.full_name, user_url(battle.owner))} has challenged #{battle.opponent.name} to a #{battle.human_battle_kind} Battle titled #{link_to(battle.description, battle_url(battle))}.
        #{link_to('Buy Your Battle Pass', battle_url(battle))}
      EOF
    else
      <<-EOF.strip_heredoc
        #{link_to(battle.owner.full_name, user_url(battle.owner))} has started a #{battle.human_battle_kind} Battle titled 
        #{link_to(battle.description, battle_url(battle))}.
      EOF
    end
  end
end
