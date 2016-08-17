class Battles::SelectSchoolForm < Reform::Form  
  property :school_object_id, readable: false
  property :school_object_type, readable: false

  validates :school_object_id, presence: true
  validates :school_object_type, presence: true

end