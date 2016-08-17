# helpers for putting flaggable stuff in the queue for school, 
# group or general monitors

module Monitorable
 extend ActiveSupport::Concern

  included do
    has_many :flags, as: :flaggable
    has_many :open_flags, -> (object) { where(action_taken: 'open') }, as: :flaggable, class_name: 'Flag'

    default_scope { where(visibility: 'visible') }
  end

  def has_open_flag?
    open_flags.size >= 1
  end

  def has_been_flag?
    flags.size >= 1
  end

  def hidden?
    visible? == false
  end

  def visible?
    visibility == 'visible'
  end

  def mark_hidden
    update_attribute(:visibility, 'hidden')
  end

  def mark_visible
    update_attribute(:visibility, 'visible')
  end

  def monitorable_parent_object
    # there is not need to assign the flag to a group or school
    return if self.is_a?(User)
    return if self.is_a?(School)
    return if self.is_a?(Battle)

    if self.is_a?(Comment)
      monitorable_parent_object_for_comment
    elsif self.is_a?(Fellowship)
      school
    elsif !self.is_a?(Group) && group.present?
      group
    elsif !self.is_a?(School) && school.present?
      school
    end
  end

  def monitorable_parent_object_for_comment
    # special handling to find the school or group of a comment because it can be further away fro the school or group
    return if object_commented_on.is_a?(Battle)
    object_commented_on = commentable_type.constantize.find(commentable_id)
    if object_commented_on.is_a?(Membership)
      object_commented_on.group
    elsif object_commented_on.is_a?(PublicActivity::ORM::ActiveRecord::Activity)
      object_commented_on.trackable
    elsif object_commented_on.school.present?
     object_commented_on.school
    elsif object_commented_on.group.present?
     object_commented_on.group
    end
  end

end