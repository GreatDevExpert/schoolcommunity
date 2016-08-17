class Battles::FindAndJoinSchoolForm < Reform::Form
  property :school_id, readable: false
  property :fellowship_role, readable: false

  validates :school_id, presence: true
  validates :fellowship_role, presence: true
end