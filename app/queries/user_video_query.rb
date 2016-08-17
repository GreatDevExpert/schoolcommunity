class UserVideoQuery
  attr_accessor :query, :filter, :user, :viewer, "page"

  def initialize(args = {})
    args.each do |k,v|
      send "#{k}=", v if respond_to? "#{k}="
    end
  end

  def videos
    if @query.blank?
      videos = filtered_videos.order('created_at DESC')
      unless show_private?
        videos = videos.where(visibility_type: 'public')
      end
      videos
    else
      searched_videos
    end
  end

  private
  def filtered_videos
    case @filter
    when 'profile'
      @user.user_videos
    when 'school'
      @user.school_videos
    when 'group'
      @user.group_videos
    else
      @user.videos
    end
  end

  def searched_videos
    # Class variables are undefined within the Sunspot block
    user = @user
    filter = @filter
    query = @query
    page = @page

    search = Sunspot.search(Video) do
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
