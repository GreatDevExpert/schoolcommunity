class FlagDismissedNotification < ApplicationNotification
  attr_accessor :flag, :flaggable

  def body
    if flaggable.is_a?(Battle)
      <<-EOF.strip_heredoc
      The flag related to your #{link_to('battle', battle_url(flaggable))}  titled #{flaggable.description} has been dismissed by a monitor. It's allowed to stay on Myschool.
      EOF
    elsif flaggable.is_a?(Comment)
      if flaggable.commentable.is_a?(PublicActivity::ORM::ActiveRecord::Activity)
        # can't user polymorphic_url(flaggable.commentable) here because an activity does not have a show view at the moment.
        <<-EOF.strip_heredoc
        The flag related to your comment "#{flaggable.content}" has been dismissed by a monitor. It's allowed to stay on Myschool.
        EOF
      else
        <<-EOF.strip_heredoc
        The flag related to your #{link_to('comment', polymorphic_url(flaggable.commentable))} has been dismissed by a monitor. It's allowed to stay on Myschool.
        EOF
      end
    elsif flaggable.is_a?(Document)
      <<-EOF.strip_heredoc
      The flag related to your #{link_to('document', document_url(flaggable))} named #{flaggable.name} has been dismissed by a monitor. It's allowed to stay on Myschool.
      EOF
    elsif flaggable.is_a?(Fellowship)
      <<-EOF.strip_heredoc
      The flag related to your membership with #{flaggable.school.name} as a  #{flaggable.role} has been dismissed by a monitor. It's allowed to stay on Myschool.
      EOF
    elsif flaggable.is_a?(Group)
      <<-EOF.strip_heredoc
      The flag realted to #{link_to(flaggable.name, group_url(flaggable))} has been dissmised by a monitor.
      EOF
    elsif flaggable.is_a?(Photo)
      <<-EOF.strip_heredoc
      The flag related to your #{link_to('photo', photo_url(flaggable))} named #{flaggable.name} has been dismissed by a monitor. It's allowed to stay on Myschool.
      EOF
    elsif flaggable.is_a?(Post)
      <<-EOF.strip_heredoc
      The flag related to your #{link_to('post', post_url(flaggable))} has been dismissed by a monitor. It's allowed to stay on Myschool. The post said: "#{flaggable.content}".
      EOF
    elsif flaggable.is_a?(School)
      <<-EOF.strip_heredoc
      The flag realted to #{link_to(flaggable.name, school_url(flaggable))} has been dissmised by a monitor.
      EOF
    elsif flaggable.is_a?(Video)
      <<-EOF.strip_heredoc
      The flag related to your #{link_to('video', video_url(flaggable))} named #{flaggable.name} has been dismissed by a monitor. It's allowed to stay on Myschool.
      EOF
    elsif flaggable.is_a?(User)
      <<-EOF.strip_heredoc
      The flag related to your account profile has been dismissed by a monitor. It's allowed to stay on Myschool.
      EOF
    else
      <<-EOF.strip_heredoc
      The flag realted to you #{flaggable.class.name.downcase} been dismissed by a monitor. It's allowed to stay on Myschool.
      EOF
    end
  end

end