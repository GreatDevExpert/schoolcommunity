class GroupActivityQuery
  def initialize(group)
    @group = group
  end

  def activities
    PublicActivity::Activity.where(recipient: @group).order("created_at DESC")
  end
end
