class FlagsController < ApplicationController
  before_action :load_flaggable, only: :create

  def create 
    @flag = @flaggable.flags.new(flag_params)
    assign_monitorable # grab the related school or group
    @flag.reporting_user = current_user
    @flag.offending_user = find_offending_user
    @flag.action_taken = 'open'
    flag_related_battle_items

    if @flag.save
      send_admin_flag_alert
      send_user_notification
      redirect_to :back, notice: 'Success. Thank you for helping keep myschool safe.'
    else
      redirect_to :back, alert: 'Must provide a reason when flagging content.'
    end
  end

  def new
    @fellowship = Fellowship.unscoped.find(params[:fellowship_id])
    @flag = @fellowship.flags.new
    @flagged_faculty_member = User.unscoped.find(@fellowship.user_id)
  end

  private

    def flag_related_battle_items
      return unless @flaggable.is_a?(Battle)
      battle = @flaggable
      if battle.first_item.present?
        battle.first_item.flags.create(offending_user: battle.first_item.user, reporting_user: current_user, action_taken: 'open', kind: 'Battle Item', description: "This item was involved in a battle that was flagged as #{@flag.kind}.")
      end
      if battle.second_item.present?
        battle.second_item.flags.create(offending_user: battle.second_item.user, reporting_user: current_user, action_taken: 'open', kind: 'Battle Item', description: "This item was involved in a battle that was flagged as #{@flag.kind}.")
      end
    end

    def flag_params
      params.require(:flag).permit(:kind, :description)
    end

    def load_flaggable
      resource, id = request.path.split('/')[1,2]
      @flaggable = resource.singularize.classify.constantize.unscoped.find(id)
    end

    def send_user_notification
      # send notification to the user who uploaded the item 
      if @flaggable.is_a?(User)
        FlagOwnerNotification.new(flaggable: @flaggable, flag: @flag, recipient: @flaggable, notifier: @flag).notify
      elsif @flaggable.is_a?(Group) || @flaggable.is_a?(School)
        @flaggable.monitors.each do |monitor|
          FlagOwnerNotification.new(flaggable: @flaggable, flag: @flag, recipient: monitor, notifier: @flag).notify
        end
      elsif @flaggable.respond_to?(:user)
        FlagOwnerNotification.new(flaggable: @flaggable, flag: @flag, recipient: @flaggable.user, notifier: @flag).notify
      elsif @flaggable.respond_to?(:owner) # for battles
        FlagOwnerNotification.new(flaggable: @flaggable, flag: @flag, recipient: @flaggable.owner, notifier: @flag).notify
      end
    end

    def assign_monitorable
      # this needs to be refactored, lookslike 
      if monitorable_object = @flaggable.monitorable_parent_object
        monitorable_object = @flaggable.monitorable_parent_object
        @flag.assign_attributes(monitorable_id: monitorable_object.id, monitorable_type: monitorable_object.class.to_s)
      end
    end

    def send_admin_flag_alert
      # send alert for a flag right way because we might need to update scores before the payouts happen.
      if @flag.flaggable.is_a?(Battle) && @flag.flaggable.kind == 'school_vs_school' &&  @flag.flaggable.closed?
        Flags::AdminAlert.perform_later(@flag)
      else
        Flags::AdminAlert.set(wait: (Flag::HOURS_UNTIL_CONSIDERED_STALE).hours).perform_later(@flag)
      end
    end

    def find_offending_user
      # for now there is no offending user if a group or school is flagged.
      return if @flag.parent_object.is_a?(School)
      return if @flag.parent_object.is_a?(Group)
      if @flag.parent_object.is_a?(User)
        @flag.parent_object
      elsif @flag.parent_object.is_a?(Battle)
        @flag.parent_object.owner
      else
        @flag.parent_object.user
      end
    end

end