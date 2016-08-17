class FacebookPost
  include Rails.application.routes.url_helpers

  attr_accessor :user, :action

  OBJECT_TYPES = %i(document photo post other)

  def initialize(attrs = {})
    attrs.each do |k,v|
      self.send "#{k}=", v if respond_to?("#{k}=")
    end

    OBJECT_TYPES.each do |object_type|
      instance_variable_set("@#{object_type}", attrs[object_type]) if attrs[object_type]
    end
  end

  def post
    return false unless user_allows_posting?
    return false unless config_allows_posting?
    raise "Action not provided" unless @action
    OBJECT_TYPES.each do |object_type|
      if value = instance_variable_get("@#{object_type}")
        if shareable?(value)
          return graph.put_connections("me", "#{ENV['FACEBOOK_APP_NAMESPACE']}:#{@action}", {object_type => url_for(value)})
        end
      end
    end
    false
  end

  private
  def user_allows_posting?
    user.settings(:settings).share_activity_on_facebook
  end

  def config_allows_posting?
    Rails.configuration.post_to_facebook
  end

  def shareable?(object)
    policy = Pundit.policy(user, object)

    return true unless policy
    return true unless policy.respond_to?(:share?)

    policy.share?
  end

  def graph
    @graph ||= FacebookGraph.new(@user.facebook_token)
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  def helpers
    ActionController::Base.helpers
  end
end
