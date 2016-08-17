class Flags::AdminAlert < ActiveJob::Base
  queue_as :mailers

  def perform(flag)
    return if flag.is_closed?
    return if (flag.created_at + 1.week) < Time.current # stop nagging after a week.
    if flag.flaggable.is_a?(Battle) && flag.flaggable.kind == 'school_vs_school' &&  flag.flaggable.closed?
      # if a battle is closed the payout job for school vs school battles has been scheduled and we want to nag more often.
      User.super_admins.each do |user|
        AdminMailer.flag_for_closed_school_vs_school(flag, user).deliver_later
      end
      Flags::AdminAlert.set(wait: 1.hours).perform_later(flag)
    else
      User.super_admins.each do |user|
        AdminMailer.stale_flag_alert(flag, user).deliver_later
      end
      Flags::AdminAlert.set(wait: 3.hours).perform_later(flag)
    end
  end

end