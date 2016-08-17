class Battles::StartGame < ActiveJob::Base
  queue_as :battles

  def perform(battle_id)
    battle = Battle.find(battle_id)

    battle.start_game
    battle.save
  end

end