class UserRegistrationNotification < ApplicationNotification
  def body
    <<-EOF.strip_heredoc
      Thank you for joining MySchool.  We hope you have fun!
    EOF
  end
end
