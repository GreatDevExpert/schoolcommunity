class Battles::AwardWinners < ActiveJob::Base
  queue_as :battles

  def perform(battle)
    battle.payout_winners
    # crate a notification?
  end

end