class SchoolActivityQuery

  def initialize(fellowships)
    @fellowships = fellowships
  end

  def activities
    activity = PublicActivity::Activity.where(recipient: school).order("created_at DESC")
    unless user_is_monitor?
      activity = activity.where(role: roles)
    end
    activity
  end

  private
  def user_is_monitor?
    @fellowships.any? { |f| f.role == 'monitor' && f.status == 'approved' }
  end

  def roles
    @fellowships.reject{ |f| f.status != 'approved' }.map(&:role).push('everyone')
  end

  def school
    @fellowships.first.school
  end
end
