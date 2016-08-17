class UserActivityQuery
  def initialize(user)
    @user = user
    @params = []
  end

  def activities
    @activity ||= PublicActivity::Activity.order("created_at DESC").where([search_sql, *@params])
  end
  
  private
  def search_sql
    [user_sql, group_sql, school_sql].reject(&:blank?).join(" OR ")
  end
  
  def user_sql
    @params << @user
    "(owner_id = ? AND owner_type = 'User' AND (recipient_type IS NULL OR recipient_type NOT IN ('Group', 'School')))"
  end

  def group_sql
    @params << groups
    @params << @user
    "(recipient_id IN (?) AND recipient_type = 'Group' AND owner_id = ? AND owner_type = 'User')"
  end

  def school_sql
    schools.map do |school_id, role|
      @params << @user
      @params << school_id
      @params << role
      "(owner_type = 'User' AND owner_id = ? AND recipient_type = 'School' AND recipient_id = ? AND (role = ? OR role = 'everyone'))"
    end
  end

  def groups
    @user.groups.where(visibility_type: 'public').pluck(:id)
  end

  def schools
    @schools ||= @user.schools.pluck(:id, :role)
  end
end
