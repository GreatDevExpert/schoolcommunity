class Battles::PickThatForm < Reform::Form
  property :second_object_id, readable: false
  property :second_object_type, readable: false
  property :opposing_user, readable: false

  validates :second_object_id, presence: true
  validates :second_object_type, presence: true

  validate :second_object_type_allowed?
  validate :second_item_is_not_same_as_first_item?

  def second_object_type_allowed?
    # we are using the send method to build the second_time object, I want to make sure the hidden value on the form can't be hack
    unless %w(photos videos documents).include?(second_object_type)
      errors[:base] << "Error message" #need to shove some error to make the record invalid. Probably a better way to do this. We are specifying the error message in the controller.
    end
  end

  def second_item_is_not_same_as_first_item?
    return if second_object_id.nil?
    if self.model.first_item  == second_object_type.classify.constantize.find(second_object_id)
      errors[:base] << "Error message" #need to shove some error to make the record invalid. Probably a better way to do this. We are specifying the error message in the controller.
    end
  end

end