class FacultyJoinNotification < ApplicationNotification
  attr_accessor :requestor, :notifier

  def body
    <<-EOF.strip_heredoc
      #{link_to(requestor.full_name, user_url(requestor))} has joined as a faculty member.  If this is not correct, please #{link_to("report this to the Myschool administrators.", new_fellowship_flag_url(notifier))}.
    EOF
  end
end
