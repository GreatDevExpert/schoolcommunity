class Flag < ActiveRecord::Base
  belongs_to :flaggable, -> { where(visibility: ['visible', 'hidden']) }, polymorphic: true # where clause ensures the default scope for Video, Photo is ignored.
  belongs_to :monitorable, -> { unscope(where: :visibility) }, polymorphic: true
  belongs_to :reporting_user, class: User, foreign_key: :reporting_user_id, unscoped: true
  belongs_to :offending_user, class: User, foreign_key: :offending_user_id, unscoped: true
  belongs_to :resolving_user, class: User, foreign_key: :resolving_user_id, unscoped: true
  validates :kind, presence: true
  validates :action_taken, presence: true

  scope :in_open_status, -> { where(action_taken: 'open') }
  scope :closed, -> { where.not(action_taken: 'open') }
  scope :stale, lambda { where(["action_taken = ? and updated_at < ?", "open", Time.current - HOURS_UNTIL_CONSIDERED_STALE.hours]) }


  # need to add a scope for all flags with monitorable_id and monitorable_type as nil so the main myschool admin can see them.

  HOURS_UNTIL_CONSIDERED_STALE = 12


  KINDS_ARRAY = [
    ['Spam' , 'spam'],
    ['Prohibited' , 'prohibited'],
    ['Nudity/Pornography' , 'nudity_pornography'],
    ['Profanity' , 'profanity'],
    ['Other' , 'other'],
  ]

  def is_open?
    action_taken == 'open'
  end

  def confirmed?
    action_taken == 'confirmed' || action_taken ==  'hide_content'
  end

  def dismissed?
    action_taken == 'dismissed' || action_taken ==  'ignored'
  end


  def is_closed?
    is_open? == false
  end

  def parent_object
    return if flaggable_type.nil?
    #must use unscoped here in case the user hides the content
    flaggable_type.constantize.unscoped.find(flaggable_id)
  end

  def is_related_to_activity?
    flaggable_type == 'PublicActivity::ORM::ActiveRecord::Activity'
  end

  def is_related_to_video?
    flaggable_type == 'Video'
  end

end
