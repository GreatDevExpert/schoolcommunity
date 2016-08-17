class RecommendationEngine
  MAX_RECOMMENDATIONS = 100
  
  def initialize(user, max = MAX_RECOMMENDATIONS)
    @user = user
    @max  = max
    @connection_types = {}
  end

  def connection_type_for(user)
    @connection_types.fetch(user.id, 'random')
  end

  def recommendations
    recommendations = filter_results(
      common_group_recommendations | common_school_recommendations | friend_of_friend_recommendations
    )
    if recommendations.count < @max
      recommendations = random_recommendations(@max - recommendations.count)
    end

    recommendations.shuffle.slice(0, @max)
  end

  def common_group_recommendations
    results = filter_results(@user.groups.flat_map { |group| group.members.limit(@max) })
    results.each { |r| @connection_types[r.id] = 'group'}
    results
  end

  def common_school_recommendations
    results = @user.schools.flat_map do |school|
      results = school.users
      if @user.birthday
        results = results.where(["birthday > ? AND birthday < ?", @user.birthday - 3.years, @user.birthday + 3.years])
      end
      results.limit(@max)
    end
    results.each { |r| @connection_types[r.id] = 'school'}
    filter_results(results)
  end

  def friend_of_friend_recommendations
    results = filter_results(User.find_by_sql(['
      SELECT u2.*
      FROM users u1
      INNER JOIN friendships f1 ON f1.user_id = u1.id
      INNER JOIN friendships f2 ON f1.friend_id = f2.user_id
      INNER JOIN users u2 ON u2.id = f2.friend_id
      WHERE u1.id = ?
      LIMIT ?', @user.id, @max]))
    results.each { |r| @connection_types[r.id] = 'mutual_friend'}
    results
  end

  def random_recommendations(count = @max)
    results = User.where.not(id: @user.id).order('RANDOM()').limit(count)
    filter_results(results)
  end

  private
  def filter_results(results)
    # Reject if self, if friend, if pending friendship request, and if not unique
    results = results.reject do |u|
      u == @user || u.friend?(@user) || u.pending_friendship_request?(@user)
    end.uniq

    if @user.is_adult?
      results = results.reject(&:minor?)
    end

    results
  end
end
