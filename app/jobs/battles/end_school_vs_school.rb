class Battles::EndSchoolVsSchool < ActiveJob::Base
  queue_as :battles

  def perform(battle_id)
    battle = Battle.find(battle_id)
    battle.waiting_for_scores
    battle.save
  end

end