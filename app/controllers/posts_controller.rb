class PostsController < ApplicationController
  before_action :set_post, only: [:show, :destroy]
  before_action :set_commentable, only: :show

  def create
    @post = current_user.posts.new(post_params)
    authorize @post
    assign_group_or_school
    if @post.save
      create_activity
      FacebookPost.new(user: current_user, action: 'add', post: @post).post
      redirect_to :back, notice: 'Successfully added to feed.'
    else
      redirect_to :back, alert: 'Must add content.'
    end
  end

  def show
    authorize @post
    set_meta_tags og: {
      title: "MySchool Post",
      type: "#{ENV['FACEBOOK_APP_NAMESPACE']}:post",
      description: @post.content,
      image: asset_url('logo_myschool_blue_beta.png'),
      url: url_for(@post),
    }
  end

  def destroy
    user = @post.user
    authorize @post
    @post.delete
    redirect_to user, notice: 'Post deleted.'
  end


  private
    def post_params
      params.require(:post).permit(:content, :identifier)
    end

    def assign_group_or_school
      if post_params[:identifier].present?
        @post.identifier = post_params[:identifier]
      elsif params[:group_id].present?
        @post.group = Group.find(params[:group_id])
      elsif params[:school_id].present?
        @post.school = School.find(params[:school_id])
      end
    end

  private

    def set_post
      @post = Post.find(params[:id])
    end

    def set_commentable
      @commentable = @post
      @comment = Comment.new
      @comments = @commentable.comments
    end

    def create_activity
      # Handle the special case when a user posts to a school and we
      # aren't sure what the fellowship type is.  In this case, we
      # publish to each fellowship type, using the same UUID to
      # prevent duplicates
      if @post.school && !@post.role
        uuid = SecureRandom.uuid
        fellowships = current_user.fellowships.where(school: @post.school, role: ['student', 'alumni', 'faculty', 'parent'])
        fellowships.each do |fellowship|
          @post.create_activity key: "post.create", owner: current_user, recipient: fellowship.school, role: fellowship.role, uuid: uuid
        end
      else
        @post.create_activity key: "post.create", owner: current_user, recipient: @post.group || @post.school, role: @post.role
      end
    end

end
