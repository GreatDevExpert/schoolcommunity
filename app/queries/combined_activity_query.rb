class CombinedActivityQuery
  def initialize(user)
    @user = user
    @params = []
  end

  def activities
    @activity ||= PublicActivity::Activity.order("created_at DESC").where([search_sql, *@params])
  end

  private
  def search_sql
    [user_is_recipient_sql, friends_sql, groups_sql, schools_sql].reject(&:blank?).join(" OR ")
  end

  def self_sql
    @params << @user
    "(owner_id = ?)"
  end

  def user_is_recipient_sql
    @params << @user
    "(recipient_id = ? AND recipient_type = 'User')"
  end

  def friends_sql
    @params << friends
    "(owner_id IN (?) AND owner_type = 'User' AND (recipient_type IS NULL OR recipient_type NOT IN ('Group', 'School')))"
  end

  def friends
    @friends ||= @user.unscoped_friends.pluck(:id)
  end

  def groups_sql
    @params << @user
    @params << groups
    "((owner_id != ? OR owner_id IS NULL) AND recipient_id IN (?) AND recipient_type = 'Group')"
  end

  def groups
    @groups ||= @user.groups.pluck(:id)
  end

  def schools_sql
    schools.map do |school_id, role|
      @params << @user
      @params << school_id
      @params << role
      "((owner_id IS NULL OR owner_id != ?) AND recipient_type = 'School' AND recipient_id = ? AND (role = ? OR role = 'everyone'))"
    end
  end

  def schools
    @schools ||= @user.schools.pluck(:id, :role)
  end
end
