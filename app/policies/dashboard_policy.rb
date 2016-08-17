class DashboardPolicy < Struct.new(:user, :dashboard)

  def users?
    return false if user.blank?
    user.super_admin?
  end

end