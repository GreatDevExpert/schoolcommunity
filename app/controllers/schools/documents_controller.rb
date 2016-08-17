class Schools::DocumentsController < ApplicationController
  before_action :set_school, only: [:new, :create]
  before_action :set_selected, only: [:new, :create]

  def new
    @document = @school.documents.build
    @comment = @document.comments.build
    authorize @document
  end

  def create
    raise Pundit::NotAuthorizedError unless SchoolPolicy.new(current_user, @school).new_post?
    @document = @school.documents.new(document_params)
    @document.user = current_user
    @comment = @document.comments.build(first_comment_params)
    authorize @document

    if @document.save
      redirect_to documents_stuff_school_path(@school, filter: 'all'), notice: 'Document uploaded.'
    else
      render :new
    end
  end

  private

    def document_params
      params.require(:document).permit(:file, :remote_file_url, :description, :name, :year)
    end

    def set_school
      @school = School.find(params[:school_id])
    end

    def first_comment_params
      params.require(:document).require(:comment).permit(:content).merge(user_id: current_user.id)
    end

    def set_selected
      fellowship = current_user.fellowships.find_by(school: @school, role: ['student', 'alumni', 'parent', 'faculty'])
      if fellowship
        @selected = fellowship.identifier
      end
    end

end
