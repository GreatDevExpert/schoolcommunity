class FindFriendsController < ApplicationController
  before_action :authenticate_user!

  def index
    @query = params[:query]
    if @query.present?
      current_user_id = current_user.id
      @search = Sunspot.search(FriendshipRecommendation) do
        all_of do
          with(:user_id, current_user_id)
        end
        fulltext params[:query] 
        order_by(:score, :desc)
      end
      @recommendations = @search.results
    else
      @recommendations = current_user.friendship_recommendations.page(params[:page]).per(20)
    end
  end
end
