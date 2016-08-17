class UserDetailsController < ApplicationController
  before_action :set_user
  before_action :authenticate_user!

  def friends
    authorize @user, :show?
    @friends = @user.friends.page(params[:page]).per(20)
  end

  def pending_friend_requests
    authorize @user, :show?
    authorize @user
    @requests = @user.pending_friendship_requests.page(params[:page]).per(20)
  end

  def sent_friend_requests
    authorize @user, :show?
    authorize @user
    @requests = @user.sent_friendship_requests.page(params[:page]).per(20)
  end

  def schools
    authorize @user, :show?
    @schools = @user.schools.page(params[:page]).per(19)
  end

  def battles
    authorize @user, :show?
    filter_type = params[:filter]
    @query = params[:q]
    if @query.blank?
      if filter_type == 'open'
        @battles = open_battles
      elsif filter_type == 'closed'
        # own battles or opposing user
        @battles = closed_battles
      end
      @battles = @battles.page(params[:page]).per(15)
    else
      user_id = @user.id
      @search = Sunspot.search(Battle) do
        any_of do
          with(:owner_id, user_id)
          with(:opposing_user_id, user_id)
        end
        all_of do
          if filter_type == 'open'
            any_of do
              with(:aasm_state, 'open_for_voting')
              with(:aasm_state, 'gametime')
              with(:aasm_state, 'pregame')
              with(:aasm_state, 'needs_scores')
            end
          elsif filter_type == 'closed'
            with(:aasm_state, 'closed')
          end
        end
        fulltext params[:q]
        paginate :page => params[:page], :per_page => 15
      end
      @battles = @search.results
    end
  end

  def rivals
    authorize @user, :show?
    filter_type = params[:filter]
    @query = params[:q]
    if @query.blank?
      if filter_type == 'people'
        @rivals = @user.rival_people.order('created_at DESC')
      elsif filter_type == 'school'
        @rivals = @user.rival_schools.order('created_at DESC')
      elsif filter_type == 'group'
        @rivals = @user.rival_groups.order('created_at DESC')
      end
      @rivals = @rivals.page(params[:page]).per(19)
    else
      user_id = @user.id
      @search = Sunspot.search(Rivalry) do
        all_of do
          with(:user_id, user_id)
          without(:school_id, nil) if filter_type == 'school'
          without(:group_id, nil) if filter_type == 'group'
          without(:rival_user_id, nil) if filter_type == 'people'
        end
        fulltext params[:q]
        paginate :page => params[:page], :per_page => 19
      end
      @rivals = @search.results
    end
  end

  def photos
    authorize @user, :show?
    @query = params[:q]
    @photos = UserPhotoQuery.new(user: @user, viewer: current_user, query: @query, filter: params[:filter], page: params[:page]).photos
    
    # need to call paginate differently when it's solr vs not
    if @query.blank?
       @photos = @photos.page(params[:page]).per(19)
    end

  end

  def groups
    authorize @user, :show?
    @query = params[:q]
    if @query.blank?
      if current_user == @user || current_user.super_admin?
        @groups = @user.groups
      else
        @groups = @user.groups.where.not(visibility_type: 'private')
      end
    else
      if current_user == @user || current_user.super_admin?
        @groups = @user.groups.where("name ilike ?", "%#{@query}%")
      else
        @groups = @user.groups.where.not(visibility_type: 'private').where("name ilike ?", "%#{@query}%")
      end
    end
  end

  def documents
    authorize @user, :show?
    @query = params[:q]
    @documents = UserDocumentQuery.new(user: @user, viewer: current_user, query: @query, filter: params[:filter], page: params[:page]).documents

    # need to call paginate differently when it's solr vs not
    if @query.blank?
       @documents = @documents.page(params[:page]).per(19)
    end
  end

  def videos
    authorize @user, :show?
    @query = params[:q]
    @videos = UserVideoQuery.new(user: @user, viewer: current_user, query: @query, filter: params[:filter], page: params[:page]).videos
    
    # need to call paginate differently when it's solr vs not
    if @query.blank?
       @videos = @videos.page(params[:page]).per(19)
    end
  end

  private
    def set_user
      if current_user && current_user.super_admin?
        @user = User.unscoped.find(params[:id])
      else
        @user = User.where(id: params[:id]).first
        if @user.blank?
          redirect_to root_url, notice: 'No such account'
        end
      end
    end

    def open_battles
      # Show where user is the owner_id or opposing_user_id
      # Show where friends are the owner_id
      # Show oppenent is a school or group that I'm a member of
      # Show challenger is a school or group that I'm a member of

      friend_ids = @user.friends.pluck(:id)
      member_school_ids = @user.schools.pluck(:id)
      member_group_ids = @user.groups.pluck(:id)

      all_open_battles = Battle.currently_active.order('created_at DESC')
      battles = all_open_battles.where([
        "(owner_id = ? OR opposing_user_id = ?) OR
           (owner_id IN (?)) OR
           (opponent_id IN (?) AND opponent_type = 'Group') OR
           (challenger_id IN (?) AND challenger_type = 'Group') OR
           (opponent_id IN (?) AND opponent_type = 'School') OR
           (challenger_id IN (?) AND challenger_type = 'School')",
           @user, @user,
           friend_ids,
           member_group_ids,
           member_group_ids,
           member_school_ids,
           member_school_ids])
      battles
    end

    def closed_battles

      # Show where user is the owner_id or opposing_user_id
      # Show where friends are the owner_id
      # Show oppenent is a school or group that I'm a member of
      # Show challenger is a school or group that I'm a member of

      friend_ids = @user.friends.pluck(:id)
      member_school_ids = @user.schools.pluck(:id)
      member_group_ids = @user.groups.pluck(:id)

      all_open_battles = Battle.currently_closed.order('created_at DESC')
      battles = all_open_battles.where([
        "(owner_id = ? OR opposing_user_id = ?) OR
           (owner_id IN (?)) OR
           (opponent_id IN (?) AND opponent_type = 'Group') OR
           (challenger_id IN (?) AND challenger_type = 'Group') OR
           (opponent_id IN (?) AND opponent_type = 'School') OR
           (challenger_id IN (?) AND challenger_type = 'School')",
           @user, @user,
           friend_ids,
           member_group_ids,
           member_group_ids,
           member_school_ids,
           member_school_ids])
      battles


      # Battle.where(aasm_state: 'closed').order('created_at DESC').where(id: @user.votes)
    end
end
