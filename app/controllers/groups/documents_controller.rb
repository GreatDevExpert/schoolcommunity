class Groups::DocumentsController < ApplicationController
  before_action :set_group, only: [:new, :create]

  def new
    @document = @group.documents.build
    @comment = @document.comments.build
  end

  def create
    raise Pundit::NotAuthorizedError unless GroupPolicy.new(current_user, @group).new_post?
    @document = @group.documents.new(document_params)
    @document.user = current_user
    @comment = @document.comments.build(first_comment_params)

    if @document.save
      redirect_to documents_stuff_group_path(@group, filter: 'all'), notice: 'Document uploaded.'
    else
      render :new
    end
  end

  private

    def document_params
      params.require(:document).permit(:file, :remote_file_url, :description, :name, :year)
    end

    def set_group
      @group = Group.find(params[:group_id])
    end

    def first_comment_params
      params.require(:document).require(:comment).permit(:content).merge(user_id: current_user.id)
    end

end