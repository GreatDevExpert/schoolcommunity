class GenerateFriendRecommendationsJob < ActiveJob::Base
  queue_as :default

  def perform(user)
    recommendation_engine = RecommendationEngine.new(user)

    # Wrap in a transaction for performance and to prevent race conditions
    ActiveRecord::Base.transaction do
      user.recommended_friends.destroy_all
      recommendation_engine.recommendations.each do |r|
        connection_type = recommendation_engine.connection_type_for(r)
        FriendshipRecommendation.create!(user: user, recommended_friend: r, connection_type: connection_type)
      end
    end
  end
end
