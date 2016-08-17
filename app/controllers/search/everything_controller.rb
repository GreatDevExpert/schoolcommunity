class Search::EverythingController < ApplicationController
  before_action :authenticate_user!

  def index
    models_to_search = [User, School, Group, Document, Video, Photo, Battle]
    # filter_by = params[:filter_by]

    # if filter_by.present?
    #   begin
    #     klass = filter_by.classify.constantize
    #   rescue
    #     raise Pundit::NotAuthorizedError
    #   end
    #   raise Pundit::NotAuthorizedError unless allowed_models_to_search.include?(klass)
    #   models_to_search = klass
    # else 
    #   models_to_search = allowed_models_to_search
    # end

    @site_query = params[:site_query]
    @search = Sunspot.search(*models_to_search) do
      all_of do
        without(:publicly_searchable, 'false')
      end
      
      fulltext params[:site_query] do
        boost_fields name: 2.0 #for categories, badges
        boost_fields full_name: 4.0 # users
        boost_fields class_nouns: 10.0 # users
      end
      facet :class_facet
      with(:class_facet, params[:filter_by]) if params[:filter_by].present?

      order_by(:score, :desc)
      order_by(:participation_level, :desc)
      paginate :page => params[:page]
    end
    render "search/index"
  end

end
