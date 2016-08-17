class CommentNotification < ApplicationNotification
  attr_accessor :commentable, :commenter, :comment

  def body
    if commentable.is_a?(PublicActivity::Activity)
      @object_commented_on = commentable.trackable
    else
       @object_commented_on = commentable
    end

    if @object_commented_on.is_a?(Battle)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on your #{link_to "#{@object_commented_on.human_battle_kind} Battle", polymorphic_url(@object_commented_on)} titled #{@object_commented_on.description}
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    elsif @object_commented_on.is_a?(Document)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on your #{link_to @object_commented_on.class.to_s.downcase, polymorphic_url(@object_commented_on)} named #{@object_commented_on.name}
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    elsif @object_commented_on.is_a?(Photo)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on your #{link_to @object_commented_on.class.to_s.downcase, polymorphic_url(@object_commented_on)} named #{@object_commented_on.name}
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    elsif @object_commented_on.is_a?(Video)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on your #{link_to @object_commented_on.class.to_s.downcase, polymorphic_url(@object_commented_on)} named #{@object_commented_on.name}
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    elsif @object_commented_on.is_a?(Post)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on your #{link_to @object_commented_on.class.to_s.downcase, polymorphic_url(@object_commented_on)} "#{@object_commented_on.content}".
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    elsif @object_commented_on.is_a?(Fellowship)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on you joining the school #{@object_commented_on.name}".
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    elsif @object_commented_on.is_a?(Membership)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on you joining the group #{@object_commented_on.name}".
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    elsif @object_commented_on.is_a?(Friendship)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented about your freindship with #{@object_commented_on.friend.name}".
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    elsif @object_commented_on.is_a?(Group)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on your group #{link_to @object_commented_on.name, group_path(@object_commented_on)}.
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    elsif @object_commented_on.is_a?(School)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on your school #{link_to @object_commented_on.name, school_path(@object_commented_on)}.
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    elsif @object_commented_on.is_a?(PublicActivity::Activity)
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on your #{link_to @object_commented_on.trackable.class.to_s.downcase, polymorphic_url(@object_commented_on.trackable)}
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    else
      <<-EOF.strip_heredoc
        #{link_to(commenter.full_name, user_url(commenter))} has commented on your #{link_to @object_commented_on.class.to_s.downcase, polymorphic_url(@object_commented_on)}
        <div class="panel callout">
          #{comment.content}
        </div>
      EOF
    end 
  end

  def send_notification?
    begin
      comment.reload
      return true
    rescue ActiveRecord::RecordNotFound
      return false
    end
  end
end
