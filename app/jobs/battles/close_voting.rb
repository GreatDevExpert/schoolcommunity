class Battles::CloseVoting < ActiveJob::Base
  queue_as :battles
  
  def perform(battle)
    battle.close_voting
    battle.save
    # if battle.winner == 'draw'
    #   BattleMailer.battle_is_closed_draw(battle, battle.owner).deliver_later
    #   BattleMailer.battle_is_closed_draw(battle, battle.opposing_user).deliver_later
    # else
    #   BattleMailer.battle_is_closed_winner(battle, battle.winner.user).deliver_later
    #   BattleMailer.battle_is_closed_loser(battle, battle.loser.user).deliver_later
    # end
  end

end