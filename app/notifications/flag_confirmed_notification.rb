class FlagConfirmedNotification < ApplicationNotification
  attr_accessor :flag, :flaggable

  def body
    if flaggable.is_a?(Battle)
      <<-EOF.strip_heredoc
      The flag related to your battle titled #{flaggable.description} has been confirmed as inappropriate for Myschool and removed by a monitor. 
      EOF
    elsif flaggable.is_a?(Comment)
      if flaggable.commentable.is_a?(PublicActivity::ORM::ActiveRecord::Activity)
        # can't user polymorphic_url(flaggable.commentable) here because an activity does not have a show view at the moment.
        <<-EOF.strip_heredoc
        The flag related to your comment "#{flaggable.content}" has been confirmed as inappropriate for Myschool and removed by a monitor. 
        EOF
      else
        <<-EOF.strip_heredoc
        The flag related to your comment has been confirmed as inappropriate for Myschool and removed by a monitor. 
        EOF
      end
    elsif flaggable.is_a?(Document)
      <<-EOF.strip_heredoc
      The flag related to your document name #{flaggable.name} has been confirmed as inappropriate for Myschool and removed by a monitor.
      EOF
    elsif flaggable.is_a?(Fellowship)
      <<-EOF.strip_heredoc
      The flag related to your membership with #{flaggable.school.name} as a  #{flaggable.role} has been confirmed as inappropriate for Myschool and removed by a monitor. 
      EOF
    elsif flaggable.is_a?(Group)
      <<-EOF.strip_heredoc
      The flag realted to #{flaggable.name} has been confirmed and the group removed from Myschool.
      EOF
    elsif flaggable.is_a?(Photo)
      <<-EOF.strip_heredoc
      The flag related to your photo named #{flaggable.name} has been confirmed as inappropriate for Myschool and removed by a monitor. 
      EOF
    elsif flaggable.is_a?(Post)
      <<-EOF.strip_heredoc
      The flag related to your post "#{flaggable.content}" has been confirmed as inappropriate for Myschool and removed by a monitor.
      EOF
    elsif flaggable.is_a?(School)
      <<-EOF.strip_heredoc
      The flag realted to #{flaggable.name} has been confirmed and the school removed from Myschool.
      EOF
    elsif flaggable.is_a?(Video)
      <<-EOF.strip_heredoc
      The flag related to your video named #{flaggable.name} has been confirmed as inappropriate for Myschool and removed by a monitor. 
      EOF
    elsif flaggable.is_a?(User)
      # not really sure what to do if they confim the user profile
      <<-EOF.strip_heredoc
      The flag related to your account profile has been confirmed. 
      EOF
    else
      <<-EOF.strip_heredoc
      The flag realted to you #{flaggable.class.name.downcase} been dismissed by a monitor. 
      EOF
    end
  end

end