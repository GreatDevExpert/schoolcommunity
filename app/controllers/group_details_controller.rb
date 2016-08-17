class GroupDetailsController < ApplicationController
  before_action :set_group
  before_action :set_role, only: :members
  before_action :authenticate_user!

  def photos
    filter_type = params[:filter]
    @query = params[:q]
    if @query.blank?
      @photos = @group.photos.order('created_at DESC').page(params[:page]).per(19)
    else
      group_id = @group.id
      @search = Sunspot.search(Photo) do
        all_of do
          with(:group_id, group_id)
        end

        fulltext params[:q] do
        boost_fields first_comment: 2.0
        end
        paginate :page => params[:page], :per_page => 19
      end
      @photos = @search.results
    end
  end

  def members
    @members = set_related_users(@group).page(params[:page]).per(20)
  end

  def documents
    filter_type = params[:filter]
    @query = params[:q]
    if @query.blank?
      @documents = @group.documents.order('created_at DESC').page(params[:page]).per(19)
    else
      group_id = @group.id
      @search = Sunspot.search(Document) do
        all_of do
          with(:group_id, group_id)
        end

        fulltext params[:q] do
        boost_fields first_comment: 2.0
        end
        paginate :page => params[:page], :per_page => 19
      end
      @documents = @search.results
    end
  end

  def battles
    if params[:filter] == 'closed'
      @battles = @group.battles.currently_closed
    else
      @battles = @group.battles.currently_active
    end
    @battles = @battles.page(params[:page]).per(15)
  end

  def videos
    filter_type = params[:filter]
    @query = params[:q]
    if @query.blank?
      @videos = @group.videos.order('created_at DESC').page(params[:page]).per(19)
    else
      group_id = @group.id
      @search = Sunspot.search(Video) do
        all_of do
          with(:group_id, group_id)
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
    @monitors = @group.monitors
    @monitor_requests = @group.monitor_requests
  end

  def new_invitation
    @invitation = Invitation.new(target: @group.identifier)
    group_query = GroupInvitableUsersQuery.new(user: current_user, group: @group)
    @eligible_users = group_query.users
  end

  def decline_invitation
    if current_user
      Membership.where(user: current_user, group: @group, role: 'invited').destroy_all
    end
    redirect_to root_path, notice: 'The invitation has been declined'
  end

  private

    def set_group
      @group = Group.find(params[:id])
    end

    def set_related_users(group)
      case @role
      when 'monitors'
        group.monitors
      when 'invited'
        group.invited
      when 'pending'
        group.membership_requests
      when 'everyone'
        group.members
      else
        group.members
      end
    end

    def set_role
      @role = params[:role] || 'everyone'
    end

end
