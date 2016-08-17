class Battles::FindAndJoinGroupForm < Reform::Form
  property :group_id, readable: false
  property :membership_role, readable: false

  validates :group_id, presence: true
  validates :membership_role, presence: true
end