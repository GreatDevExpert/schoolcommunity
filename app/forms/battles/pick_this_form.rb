class Battles::PickThisForm < Reform::Form

  property :first_object_id, readable: false
  property :first_object_type, readable: false

  validates :first_object_id, presence: true
  validates :first_object_type, presence: true

  validate :first_object_type_allowed?

  def first_object_type_allowed?
    # we are using the send method to build the first_time object, I want to make sure the hidden value on the form can't be hack
    errors[:base] << "Error message" unless %w(photos videos documents).include?(first_object_type)
  end

end