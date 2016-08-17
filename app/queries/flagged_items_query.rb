class FlaggedItemsQuery
  def initialize(user)
    @user = user
    @params = []
  end

  def open_items
    return nil unless @user
    if @user.super_admin?
      super_admin_flags.in_open_status
    else
      user_flags.in_open_status
    end
  end

  def closed_items
    return nil unless @user
    if @user.super_admin?
      super_admin_flags.closed
    else
      user_flags.closed
    end
  end

  def stale
    return nil unless @user
    if @user.super_admin?
      super_admin_flags.stale
    else
      user_flags.stale
    end
  end


  private

  def super_admin_flags
    Flag.all
  end

  def user_flags
    Flag.where(monitorable: monitored_items)
  end
  
  def monitored_items
    schools = @user.fellowships.where(role: 'monitor', status: 'approved').map(&:school)
    groups = @user.memberships.where(role: 'monitor', status: 'approved').map(&:group)
    schools + groups
  end
end
