class Search::SchoolsController < ApplicationController
  before_action :authenticate_user!

  def index
    @query = params[:school_query]
    @search = Sunspot.search(School) do
      # any_of do
      #   with(:status, 'published')
      #   with(:status, 'approved')
      #   with(:status, 'active')
      # end
      fulltext params[:school_query] do
        # highlight :content
        boost_fields name: 8.0 #for categories, badges
      end
      order_by(:score, :desc)

      paginate :page => params[:page]
    end
  end

end
