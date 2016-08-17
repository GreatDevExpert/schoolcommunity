class ScrillaBalance < ActiveRecord::Base
  belongs_to :user, unscoped: true

  validates :balance, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :lifetime_winnings, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  DEFAULT_STARTING_BALANCE = 1000
  MEMBER_REFERRAL_AMOUNT = 100
  NOTIFICATION_THRESHOLD = 50 # send a notification if drops below this

  def deposit_winnings(amount)
    with_lock do
      self.balance += amount
      self.lifetime_winnings += amount
      save!
    end
  end

  def deposit(amount)
    with_lock do
      self.balance += amount
      save!
    end
  end

  def can_deduct?(amount)
    amount <= self.balance
  end

  def deduct(amount)
    with_lock do
      self.balance -= amount
      save!
    end

    if balance < NOTIFICATION_THRESHOLD
      LowBalanceNotification.new(recipient: user).notify
    end
  end

  def self.format_amount(amount)
    symbol = "&#x24;".html_safe
    ActionController::Base.helpers.number_to_currency(amount,
      unit: symbol , precision: 0, format: "%u %n", negative_format: "&ndash; %u %n".html_safe)
  end

  def self.format_amount_html(amount)
    symbol = "<span class='scrilla-symbol'>&#x24;</span>".html_safe
    ActionController::Base.helpers.number_to_currency(amount,
      unit: symbol , precision: 0, format: "%u %n", negative_format: "&ndash; %u %n".html_safe)
  end

end
