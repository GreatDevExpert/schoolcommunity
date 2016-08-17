class Battles::AcceptChallengeForm < Reform::Form

  property :second_item_name

  validates :second_item_name,  presence: true

end