class SchoolDetailsController < ApplicationController
  before_action :set_school
  before_action :authenticate_user!

  def members
    @members = set_related_users(@school)
  end

  def photos
    filter_type = params[:filter]
    @query = params[:q]
    if @query.blank?
      @photos = @school.photos.order('created_at DESC').page(params[:page]).per(19)
    else
      school_id = @school.id
      @search = Sunspot.search(Photo) do
        all_of do
          with(:school_id, school_id)
        end

        fulltext params[:q] do
        boost_fields first_comment: 2.0
        end
        paginate :page => params[:page], :per_page => 19
      end
      @photos = @search.results
    end
  end

  def battles
    if params[:filter] == 'closed'
      @battles = @school.battles.currently_closed
    else
      @battles = @school.battles.currently_active
    end
    @battles = @battles.page(params[:page]).per(15)
  end

  def groups
    if current_user.super_admin?
      @groups = @school.groups
    else
      @groups = @school.groups.where.not(visibility_type: 'private')
    end

    @groups = @groups.page(params[:page]).per(19)
  end

  def documents
    filter_type = params[:filter]
    @query = params[:q]
    if @query.blank?
      @documents = @school.documents.order('created_at DESC').page(params[:page]).per(19)
    else
      school_id = @school.id
      @search = Sunspot.search(Document) do
        all_of do
          with(:school_id, school_id)
        end
        fulltext params[:q] do
        boost_fields first_comment: 2.0
        end
        paginate :page => params[:page], :per_page => 19
      end
      @documents = @search.results
    end
  end

  def videos
    filter_type = params[:filter]
    @query = params[:q]
    if @query.blank?
      @videos = @school.videos.order('created_at DESC').page(params[:page]).per(19)
    else
      school_id = @school.id
      @search = Sunspot.search(Video) do
        all_of do
          with(:school_id, school_id)
        end

        fulltext params[:q] do
        boost_fields first_comment: 2.0
        end
        paginate :page => params[:page], :per_page => 19
      end
      @videos = @search.results
    end
  end

  def monitors
    @monitors = @school.monitors
    @monitor_requests = @school.monitor_requests
  end

  def about
  end

  private

    def set_school
      @school = School.find(params[:id])
    end

    def set_related_users(school)
      role = params[:role]
      raise Pundit::NotAuthorizedError unless %w(student parent alumni faculty).include?(role)
      @query = params[:q]
      @selected_year = params[:grad_year]
      if params[:grad_year].present?
        school_id = @school.id
        selected_year =  @selected_year
        @search = Sunspot.search(Fellowship) do
          all_of do
            with(:role_name, role)
            with(:school_id, school_id)
            without(:publicly_searchable, 'false')
          end
          fulltext @query
          paginate :page => params[:page], :per_page => 20
        end
        @search.results
      else
        school_id = @school.id
        @search = Sunspot.search(Fellowship) do
          all_of do
            with(:role_name, role)
            with(:school_id, school_id)
            without(:publicly_searchable, 'false')
          end
          fulltext @query
          facet :graduation_year
          paginate :page => params[:page], :per_page => 20
        end
        @search.results
      end
    end
end
