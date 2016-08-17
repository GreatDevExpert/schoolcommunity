class MembershipsController < ApplicationController
  before_action :set_group, only: [:join, :leave, :new_monitor_request, :step_down_as_monitor]

  # join a group
  def join
    @membership = @group.join_group(current_user)

    # Generate activity
    if @group.visibility_type == 'moderated'
      @group.monitors.each do |monitor|
        GroupJoinRequestNotification.new(recipient: monitor, requestor: current_user, group: @group).notify
      end
      redirect_to :back, notice: "Membership request has been sent to #{@group.name}. You will be notified when approved."
    else
      redirect_to :back, notice: "Successfully joined #{@group.name}."
    end
  end

  # leave a group
  def leave
    @memberships = current_user.memberships.where(group: @group)
    user = @memberships.first.user
    @memberships.destroy_all

    @group.create_activity key: 'group.member_left', owner: user, recipient: @group
    redirect_to root_path, notice: "You left the group: #{@group.name}."
  end

  def new_monitor_request
    authorize @group
    @membership = Membership.where(user: current_user, group: @group).first_or_initialize(user: current_user, group: @group)

    if @group.visibility_type == 'public' && @group.monitors.count == 0
      if @membership.update(role: 'monitor', status: 'approved')
        redirect_to group_path(@group), notice: "You have been promoted to monitor of this group"
      else
        redirect_to group_path(@group), alert: "An error occurred processing your monitor request"
      end
    elsif @membership.update(role: 'monitor', status: 'pending')
      #@membership.create_activity key: 'membership.create', owner: @membership.user, recipient: @membership.group

      @group.monitors.each do |monitor|
        GroupMonitorRequestNotification.new(recipient: monitor, requestor: current_user, group: @group).notify
      end

      redirect_to group_path(@group), notice: "Monitor request has been received."
    else
      redirect_to group_path(@group), alert: "Sorry, you can't become a monitor of #{@group.name}."
    end
  end

  def step_down_as_monitor
    authorize @group, :leave_as_monitor?
    @memberships = current_user.memberships.where(group: @group, role: 'monitor')
    @memberships.update_all(role: 'standard', status: nil)

    redirect_to monitors_group_path(@group), notice: "You are no longer a monitor of #{@group.name}."
  end

  def approve_monitor
    @membership = Membership.find(params[:id])
    @group = @membership.group
    authorize @membership

    if @membership.update(role: 'monitor', status: 'approved')
      GroupMonitorNotification.new(recipient: @membership.user, group: @group).notify
      redirect_to monitors_group_path(@group), notice: "#{@membership.user.full_name} is now a monitor of #{@group.name}."
    else
      redirect_to monitors_group_path(@group), alert: "Could not approve #{@membership.user.full_name} as a monitor #{@group.name}."
    end
  end

  def approve_join
    @membership = Membership.find(params[:id])
    @group = @membership.group
    authorize @group

    if @membership.update_attributes(role: 'standard', status: 'approved')
      GroupJoinApprovedNotification.new(recipient: @membership.user, group: @group).notify
      redirect_to :back, notice: "Membership has been approved"
    else
      redirect_to :back, alert: "An error occurred approving this membership"
    end
  end

  def decline_join
    @membership = Membership.find(params[:id])
    @group = @membership.group
    authorize @group, :approve_join?

    if @membership.destroy
      GroupJoinDeclinedNotification.new(recipient: @membership.user, group: @group).notify
      redirect_to :back, notice: "Membership has been declined"
    else
      redirect_to @group, alert: "An error occurred declining user"
    end
  end

  def decline_monitor
    @membership = Membership.find(params[:id])
    @group = @membership.group
    authorize @membership, :approve_monitor?

    if @membership.update(role: 'standard', status: nil)
      GroupMonitorDeclinedNotification.new(recipient: @membership.user, group: @group).notify
      redirect_to monitors_group_path(@group), notice: "The request to be a monitor has been declined"
    else
      redirect_to monitors_group_path(@group), alert: "An error occurred declining this membership"
    end
  end

  private 

    def set_group
      @group = Group.find(params[:id])
    end

end
