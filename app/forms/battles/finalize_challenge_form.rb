class Battles::FinalizeChallengeForm < Reform::Form

  property :description
  property :first_item_name
  property :battle_length

  validates :description, presence: true
  validates :first_item_name, presence: true
  validates :battle_length, presence: true
end