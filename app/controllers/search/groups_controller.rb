class Search::GroupsController < ApplicationController
  before_action :authenticate_user!

  def index
    @query = params[:group_query]
    @search = Sunspot.search(Group) do
      all_of do
        without(:publicly_searchable, 'false')
      end
      # any_of do
      #   with(:status, 'published')
      #   with(:status, 'approved')
      #   with(:status, 'active')
      # end
      fulltext params[:group_query] do
        # highlight :content
        boost_fields name: 8.0 #for categories, badges
      end
      order_by(:score, :desc)

      paginate :page => params[:page]
    end
  end

end
