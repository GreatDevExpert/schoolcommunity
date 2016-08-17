class GroupInvitableUsersQuery
  def initialize(user: user, group: group)
    @user = user
    @group = group
  end

  def users
    if @group.school.present? && user_is_faculty?
      students | friends
    else
      friends
    end
  end

  private

  def students
    @group.school.students
  end

  def friends
    @user.friends.where.not(friendships: {friend_id: group_invitees | group_members})
  end

  def group_invitees
    @group_invitees ||= @group.invited.pluck(:id)
  end

  def group_members
    @group_members ||= @group.members.pluck(:id)
  end

  def user_is_faculty?
    return false unless @user
    return false unless @group.school.present?

    Fellowship.where(user: @user).where(school: @group.school).where(role: 'faculty').exists?
  end
end
