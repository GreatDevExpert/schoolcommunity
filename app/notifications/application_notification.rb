class ApplicationNotification
  include Rails.application.routes.url_helpers

  attr_accessor :recipient, :notifier

  def self.deserialize(serialized_object)
    YAML::load(serialized_object)
  end

  def initialize(attrs = {})
    attrs.each do |k,v|
      self.send "#{k}=", v if respond_to?("#{k}=")
    end
  end

  def body
    "You have received a notification"
  end

  def mailer
    return @mailer if @mailer

    if @recipient && @recipient.respond_to?(:email)
      @mailer = NotificationMailer.new(@recipient, self)
    end
    @mailer
  end

  def notify
    @recipient.notify(self)
  end

  def link_to(text, url, *args)
    # Make sure url is HTTPS for embedding in frames
    url.gsub!(/\Ahttp:\/\//, 'https://') unless Rails.env.development?
    protocol = Rails.env.development? ? 'http' : 'https'
    trackable_url = notifications_reader_url(uuid, url: url, protocol: protocol)
    ActionController::Base.helpers.link_to(text, trackable_url, *args)
  end

  def uuid
    @uuid ||= SecureRandom.uuid
  end

  def notify_later
    DelayedNotificationJob.set(wait: 60.seconds).perform_later(@recipient, self.serialize)
  end

  def send_notification?
    true
  end

  def serialize
    YAML::dump(self)
  end

  private
  def unindent(s)
    s.gsub(/^#{s.scan(/^[ \t]+(?=\S)/).min}/, "")
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end
end
