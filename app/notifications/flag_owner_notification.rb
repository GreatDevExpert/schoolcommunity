class FlagOwnerNotification < ApplicationNotification
  attr_accessor :flaggable, :flag

  def body
    if flaggable.is_a?(Battle)
      <<-EOF.strip_heredoc
      A #{link_to('battle', battle_url(flaggable))} you've started has been flagged. The battle title is #{flaggable.description}.
      EOF
    elsif flaggable.is_a?(Comment)
      if flaggable.commentable.is_a?(PublicActivity::ORM::ActiveRecord::Activity)
        # can't user polymorphic_url(flaggable.commentable) here because an activity does not have a show view at the moment.
        <<-EOF.strip_heredoc
        A comment you've added has been flagged. The comment said: "#{flaggable.content}".
        EOF
      else
        <<-EOF.strip_heredoc
        A #{link_to('comment', polymorphic_url(flaggable.commentable))} you've added has been flagged. The comment said: "#{flaggable.content}".
        EOF
      end
    elsif flaggable.is_a?(Document)
      <<-EOF.strip_heredoc
      A #{link_to('document', document_url(flaggable))} you've added has been flagged. The document's name is #{flaggable.name}.
      EOF
    elsif flaggable.is_a?(Fellowship)
      <<-EOF.strip_heredoc
      You membership with #{flaggable.school.name} as a #{flaggable.role} has been flagged.
      EOF
    elsif flaggable.is_a?(Group)
      <<-EOF.strip_heredoc
      A #{link_to('group', group_url(flaggable))} you're a monitor of has been flagged. The group's name is #{flaggable.name}.
      EOF
    elsif flaggable.is_a?(Photo)
      <<-EOF.strip_heredoc
      A #{link_to('photo', photo_url(flaggable))} you've added has been flagged. The photo's name is #{flaggable.name}.
      EOF
    elsif flaggable.is_a?(Post)
      <<-EOF.strip_heredoc
      A #{link_to('post', post_url(flaggable))} you've added has been flagged. The post said: "#{flaggable.content}".
      EOF
    elsif flaggable.is_a?(School)
      <<-EOF.strip_heredoc
      A #{link_to('school', school_url(flaggable))} you're a monitor of has been flagged. The school's name is #{flaggable.name}.
      EOF
    elsif flaggable.is_a?(Video)
      <<-EOF.strip_heredoc
      An video you've added has been flagged. The video's name is #{flaggable.name}.
      EOF
    elsif flaggable.is_a?(User)
      <<-EOF.strip_heredoc
      You account profile has been flagged.
      EOF
    else
      <<-EOF.strip_heredoc
      A #{flaggable.class.name.downcase} you've added has been flagged.
      EOF
    end
  end
end
