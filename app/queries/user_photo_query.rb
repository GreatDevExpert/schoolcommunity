class UserPhotoQuery
  attr_accessor :query, :filter, :user, :viewer, :page

  def initialize(args = {})
    args.each do |k,v|
      send "#{k}=", v if respond_to? "#{k}="
    end
  end

  def photos
    if @query.blank?
      photos = filtered_photos.order('created_at DESC')
      unless show_private?
        photos = photos.where(visibility_type: 'public')
      end
      photos
    else
      searched_photos
    end
  end

  private
  def filtered_photos
    case @filter
    when 'profile'
      @user.user_photos
    when 'school'
      @user.school_photos
    when 'group'
        @user.group_photos
    else
      @user.photos
    end
  end

  def searched_photos
    # Class variables are undefined within the Sunspot block
    user = @user
    filter = @filter
    query = @query
    page = @page

    search = Sunspot.search(Photo) do
      all_of do
        with(:user_id, user.id)
        if filter == 'school'
          without(:school_id, nil)
        elsif filter == 'group'
          without(:group_id, nil)
        elsif filter == 'profile'
          with(:group_id, nil)
          with(:school_id, nil)
        end
        unless show_private?
          without(:publicly_searchable, 'false')
        end
      end
      fulltext query do
      boost_fields first_comment: 2.0
      end
      paginate :page => page, :per_page => 19
    end
    search.results
  end

  def show_private?
    return false unless user && viewer
    user == viewer || viewer.super_admin?
  end

end
