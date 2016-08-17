class Battles::SelectGroupOpponentForm < Reform::Form
  
  property :group_object_id, readable: false
  property :group_object_type, readable: false

  validates :group_object_id, presence: true
  validates :group_object_type, presence: true

end