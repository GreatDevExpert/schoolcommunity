class FacebookPayment < ActiveRecord::Base
  belongs_to :user, unscoped: true

  after_initialize :init
  def init
    self.uuid ||= SecureRandom.uuid
  end

  validates :user, :presence => true

  include AASM
  aasm column: :aasm_state do
    state :initialized, initial: true
    state :pending
    state :succeeded
    state :failed

    event :set_pending do
      transitions from: :initialized, to: :pending
    end
    event :complete_successfully do
      transitions from: [:initialized, :pending], to: :succeeded
    end
    event :complete_unsuccessfully do
      transitions from: [:initialized, :pending], to: :failed
    end
  end
end
