class ScrillaTransfer < ActiveRecord::Base
  include AASM

  TRANSFER_TYPES = %w(initial_deposit transfer facebook_purchase battle_purchase battle_pass battle_pass_upgrade battle_payout_winner battle_payout_draw admin_adjustment member_referral)

  belongs_to :sender, class_name: User
  belongs_to :recipient, class_name: User

  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validates :transfer_type, presence: true, inclusion: { in: TRANSFER_TYPES }

  validate :amount_can_not_be_greater_than_sender_balance
  def amount_can_not_be_greater_than_sender_balance
    if sender.present? && amount.present? && amount > sender.scrilla_balance.balance
      errors.add(:amount, "amount can't be greater than sender balance")
    end
  end

  validate :recipient_must_be_set_for_certain_transfer_types
  def recipient_must_be_set_for_certain_transfer_types
    if %w(initial_deposit transfer facebook_purchase).include?(transfer_type)
      unless recipient.present?
        errors.add(:recipient, "recipient required")
      end
    end
  end

  aasm do
    state :pending, :initial => true
    state :complete, :before_enter => :before_complete

    event :complete do
      transitions from: :pending, to: :complete, guard: :valid?
    end
  end

  def invert!
    self.amount = -(self.amount)
    # we swap the sender and receiver for negative amounts so
    # the ledger looks right. If I take money, I am the recipient.
    self.recipient, self.sender = self.sender, self.recipient
  end

  private
  def before_complete
    if sender.present?
      sender.scrilla_balance.deduct(amount)
    end
    if recipient.present?
      if transfer_type == 'battle_payout_winner'
        recipient.scrilla_balance.deposit_winnings(amount)
      else
        recipient.scrilla_balance.deposit(amount)
      end
    end
  end
end
