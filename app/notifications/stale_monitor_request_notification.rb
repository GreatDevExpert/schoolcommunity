class StaleMonitorRequestNotification < ApplicationNotification
  def body
    <<-EOF.strip_heredoc
      There are unapproved monitor requests in your queue.  Please visit the #{link_to("monitor request queue", admin_monitor_requests_path)}
    EOF
  end
end
