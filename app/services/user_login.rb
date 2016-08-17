class UserLogin
  def initialize(user)
    @user = user
  end

  def complete_login
    generate_friend_recommendations
  end


  private
    def generate_friend_recommendations
      if @user.recommended_friends.count == 0
        # If we don't have any recommendations yet, generate them immediately
        # Wrap in a transaction for performance
        ActiveRecord::Base.transaction do
          recommendation_engine = RecommendationEngine.new(@user)
          recommendation_engine.recommendations.each do |r|
            connection_type = recommendation_engine.connection_type_for(r)
            FriendshipRecommendation.create(user: @user, recommended_friend: r, connection_type: connection_type)
          end
        end
      else
        # Otherwise do it as a job
        GenerateFriendRecommendationsJob.perform_later(@user)
      end
    end
end
