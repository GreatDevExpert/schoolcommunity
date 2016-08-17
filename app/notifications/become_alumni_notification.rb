class BecomeAlumniNotification < ApplicationNotification
  attr_accessor :fellowship

  def body
    <<-EOF.strip_heredoc
    Congratulations, you have become an alumni of #{fellowship.school.full_name}!
    EOF
  end
end
