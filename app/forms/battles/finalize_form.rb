class Battles::FinalizeForm < Reform::Form
  property :battle_length

  validates :battle_length,  presence: true
  validate :battle_length_allowed?

  def battle_length_allowed?
    # we are using the send method to build the first_time object, I want to make sure the hidden value on the form can't be hack
    errors[:base] << "Error message" unless Battle::LENGTH_OPTIONS.flatten.include?(battle_length)
  end

end