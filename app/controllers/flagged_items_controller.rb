class FlaggedItemsController < ApplicationController
  before_action :load_school_or_group
  before_action :load_flagged_item, only: [:show, :ignore, :hide_content]

  def index
    raise Pundit::NotAuthorizedError unless FlaggedItemsPolicy.new(current_user, nil).index?
    raise Pundit::NotAuthorizedError unless ['open', 'closed', 'stale'].include?(params[:tab])

    set_flags_by_tab
  end

  def show
    @flagged_object = @flag.flaggable
    raise Pundit::NotAuthorizedError unless FlaggedItemsPolicy.new(current_user, @flag).show?
  end

  def ignore
    raise Pundit::NotAuthorizedError unless FlaggedItemsPolicy.new(current_user, @flag).ignore?
    @flag.action_taken = 'dismissed'
    @flag.resolving_user = current_user

    if @flag.save
      mark_hidden_content_visible
      send_notification
      redirect_to admin_flagged_item_path(@flag), notice: 'Flag dismissed.'
    else
      redirect_to admin_flagged_item_path(@flag), alert: 'Could not ignore flag.'
    end
  end

  def hide_content
    raise Pundit::NotAuthorizedError unless FlaggedItemsPolicy.new(current_user, @flag).hide_content?
    @flag.action_taken = 'confirmed'
    @flag.resolving_user = current_user

    if @flag.save
      unless @flag.flaggable.is_a? User
        @flag.flaggable.update_attribute(:visibility, 'hidden')
      end
      hide_related_objects
      remove_related_notifications
      send_notification
      redirect_to admin_flagged_item_path(@flag), notice: 'Flag confirmed. Content has been hidden from standard users.'  
    else
      redirect_to admin_flagged_item_path(@flag), alert: 'Could not hide the content.'
    end
  end

  private

    def set_flags_by_tab
      viewed_tab = params[:tab]
      if viewed_tab == 'open'
        @flags = FlaggedItemsQuery.new(current_user).open_items.order('created_at DESC').page params[:page]

      elsif viewed_tab == 'closed'
        @flags = FlaggedItemsQuery.new(current_user).closed_items.order('created_at DESC').page params[:page]

      elsif viewed_tab == 'stale'
        @flags = FlaggedItemsQuery.new(current_user).stale.order('created_at DESC').page params[:page]
      end
    end

    def mark_hidden_content_visible
      # need to unscope at the class level to find the hidden record
      @flag.flaggable.update_attribute(:visibility, 'visible')
    end

    def send_notification
      if @flag.action_taken == 'dismissed'
        send_dismissed_notifications
      elsif @flag.action_taken == 'confirmed'
        send_confirmed_notifications
      end
    end

    def send_dismissed_notifications
      if @flag.flaggable.respond_to?(:monitors)
        # send to all the School or Group monitors
        @flag.flaggable.monitors.each do |monitor|
          FlagDismissedNotification.new(flaggable: @flag.flaggable, flag: @flag, recipient: monitor, notifier: @flag).notify
        end
      else
        # just send to the offending user
        FlagDismissedNotification.new(flaggable: @flag.flaggable, flag: @flag, recipient: @flag.offending_user, notifier: @flag).notify
      end
    end

    def send_confirmed_notifications
      if @flag.flaggable.respond_to?(:monitors)
        # send to all the School or Group monitors
        @flag.flaggable.monitors.each do |monitor|
          FlagConfirmedNotification.new(flaggable: @flag.flaggable, flag: @flag, recipient: monitor, notifier: @flag).notify
        end
      else
        FlagConfirmedNotification.new(flaggable: @flag.flaggable, flag: @flag, recipient: @flag.offending_user, notifier: @flag).notify
      end
    end


    def load_flagged_item
      @flag = Flag.unscoped.find(params[:id])
    end

    def load_school_or_group
      if params[:school_id].present?
        @school = School.find(params[:school_id])
      elsif params[:group_id].present?
        @group = Group.find(params[:group_id])
      end
    end

    def hide_related_objects
      if @flag.flaggable.is_a?(Photo)
        photo = @flag.flaggable
        photo.battles.each { |b| b.mark_hidden }
      elsif @flag.flaggable.is_a?(Video)
        video = @flag.flaggable
        video.battles.each { |b| b.mark_hidden }
      end
      if @flag.flaggable.respond_to?(:comments)
        @flag.flaggable.comments.each { |c| c.mark_hidden }
      end
    end

    def remove_related_notifications
      Notification.where(notifier: @flag.flaggable).destroy_all
    end

end
