class NotificationMailer < ActionMailer::Base
  default from: "MySchool <info@myschool411.com>"

  def new_notification_email(recipient, body)
    @recipient = recipient
    @body = body
    mail to: recipient.email, subject: "You have received a notification"
  end
  
end
