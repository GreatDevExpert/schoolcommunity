class Battles::SelectOpponentForm < Reform::Form

  property :opponent_object_id, readable: false
  property :opponent_object_type, readable: false

  validates :opponent_object_id, presence: true
  validates :opponent_object_type, presence: true

end