class UserDocumentQuery
  attr_accessor :query, :filter, :user, :viewer, :page

  def initialize(args = {})
    args.each do |k,v|
      send "#{k}=", v if respond_to? "#{k}="
    end
  end

  def documents
    if @query.blank?
      documents = filtered_documents.order('created_at DESC')
      unless show_private?
        documents = documents.where(visibility_type: 'public')
      end
      documents
    else
      searched_documents
    end
  end

  private
  def filtered_documents
    case @filter
    when 'profile'
      @user.user_documents
    when 'school'
      @user.school_documents
    when 'group'
      @user.group_documents
    else
      @user.documents
    end
  end

  def searched_documents
    # Class variables are undefined within the Sunspot block
    user = @user
    filter = @filter
    query = @query
    page = @page
    search = Sunspot.search(Document) do
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
