class BattleChallengeNotification < ApplicationNotification
  attr_accessor :battle

  def body
    if battle.kind == 'group_vs_group'
      <<-EOF.strip_heredoc
        #{link_to(battle.owner.full_name, user_url(battle.owner))} has challenged #{link_to(battle.opponent.name, group_url(battle.opponent))} to a #{battle.human_battle_kind} Battle titled #{link_to(battle.description, battle_group_vs_group_url(battle, 'pick_that')) }.
        #{link_to('Accept Challenge', battle_group_vs_group_url(battle, 'pick_that'))}
      EOF
    else
      <<-EOF.strip_heredoc
        #{link_to(battle.owner.full_name, user_url(battle.owner))} has challenged you to a #{battle.human_battle_kind} Battle titled #{link_to(battle.description, battle_me_vs_you_url(battle, 'pick_that'))}.
        #{link_to('Accept Challenge', battle_me_vs_you_url(battle, 'pick_that'))}
      EOF
    end
  end

end
