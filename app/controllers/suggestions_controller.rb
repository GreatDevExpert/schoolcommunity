class SuggestionsController < ApplicationController
  before_action :set_suggestion, only: [:approve, :decline]
  before_filter :load_suggestible, only: [:new, :create]

  def index
    raise Pundit::NotAuthorizedError unless SuggestionPolicy.new(current_user, nil).index?
    @suggestions = Suggestion.where(action_taken: 'open')
    # @suggestions = Suggestion.all
  end

  def new
    @suggestion = Suggestion.new
    @kind = params[:kind]
  end

  def create
    @suggestion = @suggestible.suggestions.new(new_suggestion_params)
    @kind = @suggestion.kind
    @suggestion.action_taken = 'open'
    @suggestion.user = current_user
    if @suggestion.save
      send_monitor_notifications

      redirect_to @suggestible, notice: "Your suggestion has been received! We will notify you with an update soon."
    else
      render :new
    end
  end

  def approve
    # TODO can't get this feature to work in dev, moving on for now. Tested and passing.
    raise Pundit::NotAuthorizedError unless SuggestionPolicy.new(current_user, @suggestion).approve_or_decline?

    @suggestible = @suggestion.suggestible

      if @suggestion.kind == 'logo'
        @suggestible.avatar = @suggestion.avatar
      elsif @suggestion.kind == 'about'
        @suggestible.description = @suggestion.content
      end

    if @suggestible.save
      @suggestion.update_attributes(action_taken: 'accepted', resolving_user: current_user)
      create_suggestion_approved_activity
      redirect_to @suggestible, notice: 'Suggestion Accepted'
    else
      redirect_to :back, alert: 'Could not approve this suggestion.'
    end
  end

  def decline
    raise Pundit::NotAuthorizedError unless SuggestionPolicy.new(current_user, @suggestion).approve_or_decline?

    @suggestion.assign_attributes(action_taken: 'declined', resolving_user: current_user)

    if @suggestion.save
      redirect_to suggestions_path, notice: 'Suggestion Declined'
      SuggestionDeclinedNotification.new(suggestion: @suggestion, recipient:  @suggestion.user).notify
    else
      redirect_to :back, alert: 'Could not decline this suggestion.'
    end
  end

  private

    def send_monitor_notifications
      if @suggestible.monitors.blank?
        User.super_admins.each do |user|
          SuggestionNotification.new(suggestion: @suggestion, recipient: user, suggester: @suggestion.user).notify
        end
      else
        @suggestible.monitors.each do |user|
          SuggestionNotification.new(suggestion: @suggestion, recipient: user, suggester: @suggestion.user).notify
        end
      end
    end

    def set_suggestion
      @suggestion = Suggestion.find(params[:id])
    end

    def load_suggestible
      resource, id = request.path.split('/')[1,2]
      @suggestible = resource.singularize.classify.constantize.find(id)
    end

    def new_suggestion_params
      kind = params[:suggestion][:kind]
      if kind == 'logo'
        params.require(:suggestion).permit(:avatar, :kind, :existing_photo_id)
      elsif kind == 'about'
        params.require(:suggestion).permit(:content, :kind)
      end
    end

    def create_suggestion_approved_activity
      if @suggestion.kind == 'logo'
        @suggestion.create_activity action: "new_logo", owner: @suggestion.resolving_user, recipient: @suggestible, role: 'everyone'
      elsif @suggestion.kind == 'about'
        @suggestion.create_activity action: "new_about", owner: @suggestion.resolving_user, recipient: @suggestible, role: 'everyone'
      end
      SuggestionApprovedNotification.new(suggestion: @suggestion, recipient:  @suggestion.user).notify
    end

end
