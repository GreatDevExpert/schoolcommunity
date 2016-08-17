class Pass < ActiveRecord::Base
  belongs_to :battle, counter_cache: :pass_count
  belongs_to :user, counter_cache: :pass_count, unscoped: true

  validates :kind, presence: true, inclusion: { in: %w(challenger opponent) }
  validates :amount, presence: true

  AMOUNTS = [
    [50, 50],
    [100, 100],
    [500, 500],
  ]

end
