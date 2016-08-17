class ParentChildRelationship < ActiveRecord::Base
  belongs_to :parent, class_name: 'User', foreign_key: 'parent_id'
  belongs_to :child, class_name: 'User', foreign_key: 'child_id'
  belongs_to :requesting_user, class_name: 'User', foreign_key: 'requesting_user_id'

  after_create :send_request_notification
  before_destroy :remove_parent_fellowships

  validates_uniqueness_of :parent_id, scope: :child_id
  validates_presence_of :child
  validates_presence_of :parent
  validates_presence_of :requesting_user

  include AASM
  aasm column: :aasm_state do
    state :pending_approval, initial: true
    state :approved

    event :approve, after: -> { approve_relationship && establish_parent_fellowships } do
      transitions from: :pending_approval, to: :approved
    end
  end

  def receiving_user
    if requesting_user == parent
      child
    else
      parent
    end
  end

  private
  def send_request_notification
    ParentChildRelationshipRequestNotification.new(recipient: receiving_user, requestor: requesting_user).notify
  end

  def approve_relationship
    ParentChildRelationshipApprovedNotification.new(recipient: requesting_user, approving_user: receiving_user).notify
  end

  def establish_parent_fellowships
    child.fellowships.where(role: 'student').each do |fellowship|
      parent.fellowships.create(school: fellowship.school, role: 'parent', status: 'approved', graduation_date: fellowship.graduation_date)
    end
  end

  def remove_parent_fellowships
    child.fellowships.where(role: 'student').each do |fellowship|
      fellowship = Fellowship.find_by(user: parent, school: fellowship.school, role: 'parent', graduation_date: fellowship.graduation_date)
      fellowship.destroy! if fellowship
    end
  end
end
