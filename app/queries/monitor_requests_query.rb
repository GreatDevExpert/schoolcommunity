class MonitorRequestsQuery
  def initialize(user)
    @user = user
    @params = []
  end

  def groups
    return [] unless @user
    if @user.super_admin?
      super_admin_groups
    else
      user_groups
    end
  end

  def schools
    return [] unless @user
    if @user.super_admin?
      super_admin_schools
    else
      user_schools
    end
  end

  private
  def super_admin_groups
    Group.joins(:memberships).where(memberships: {role: 'monitor', status: 'pending'}).distinct
  end

  def super_admin_schools
    School.joins(:fellowships).where(fellowships: {role: 'monitor', status: 'pending'}).distinct
  end

  def user_groups
    groups = @user.memberships.where(role: 'monitor', status: 'approved').pluck(:group_id)
    return [] unless groups.present?
    Group.joins(:memberships).where(memberships: {role: 'monitor', status: 'pending'}, id: groups).distinct
  end

  def user_schools
    schools = @user.fellowships.where(role: 'monitor', status: 'approved').pluck(:school_id)
    return [] unless schools.present?
    School.joins(:fellowships).where(fellowships: {role: 'monitor', status: 'pending'}, id: schools).distinct
  end
end
