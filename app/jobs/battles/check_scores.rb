class Battles::CheckScores < ActiveJob::Base
  queue_as :notifications

  def perform(battle_id)
    battle = Battle.find(battle_id)

    #stop nagging after 12 hours
    return if battle.ends_at.in_time_zone + 12.hours < Time.current

    if battle.winner.blank? # continue cycle only if the battle does not have a winner selected
      BattleNeedsScoreNotification.new(battle: battle, recipient: battle.owner, notifier: battle).notify
      Battles::CheckScores.set(wait: 30.minutes).perform_later(battle.id)
    end
  end

end