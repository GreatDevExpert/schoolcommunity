class CommentsController < ApplicationController
  before_filter :load_commentable, only: [:index, :new, :create]

  def index
    @comments = @commentable.comments
  end

  def new
    @comment = Comment.new
    authorize @comment
  end
  
  def show
    @comment = Comment.find(params[:id])
  end

  def create
    @comment = @commentable.comments.new(comment_params)
    authorize @comment
    @comment.user = current_user

    if @comment.save
      create_activity
      send_notifications(@commentable)
      render partial: "comments/comment", locals: { :comment => @comment }, status: :created
    else
      render :js => "alert('error saving comment');"
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @commentable = @comment.commentable
    authorize @comment
    @comment.mark_hidden
    redirect_to :back, notice: "Comment deleted."
  end

private

  def create_activity
    return if @commentable.is_a?(PublicActivity::ORM::ActiveRecord::Activity)
    # group and school does not exist for some objects like a battle
    if @commentable.respond_to?(:group)
      parent_object = @commentable.group
    elsif @commentable.respond_to?(:school)
      parent_object = @commentable.school
    else
      parent_object = nil
    end

    @comment.create_activity key: "comment.create", owner: current_user, role: current_user.fellowship_for_school(parent_object), recipient: parent_object
  end

  def load_commentable
    if activity_id = params[:public_activity_activity_id]
      @commentable = PublicActivity::Activity.find(activity_id)
    else
      resource, id = request.path.split('/')[1,2]
      @commentable = resource.singularize.classify.constantize.find(id)
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def send_notifications(commentable)
    if commentable.respond_to?(:notification_users)
      commentable.notification_users.each do |user|
        unless user == current_user
          CommentNotification.new(recipient: user, comment: @comment, commentable: commentable, commenter:  @comment.user, notifier: @comment).notify_later
        end
      end
    end
  end
end
