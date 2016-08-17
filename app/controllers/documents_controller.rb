class DocumentsController < ApplicationController
  before_action :set_document_objects, only: [:show, :destroy, :duplicate, :repost]
  before_action :set_commentable, only: :show

  def selector
    @documents = current_user.documents.page(params[:page]).per(10)
    if params[:q].present?
      @documents = @documents.where("name ILIKE ?", "%#{params[:q]}%")
    end

    render partial: 'documents/selector', layout: false
  end

  def new
    @document = current_user.documents.new
  end

  def create
    @document = current_user.documents.new(document_params)
    validate_group_and_school_permissions

    @document.visibility_type = document_params[:identifier] == 'private' ? 'private' : 'public'

    if @document.save
      if @document.visibility_type == 'public'
        create_activity
        FacebookPost.new(user: current_user, action: 'add', document: @document).post
      end
      resolve_new_document_redirect
    else
      render :new
    end
  end

  def show
    authorize @document
    set_meta_tags og: {
      title: @document.name,
      type: "#{ENV['FACEBOOK_APP_NAMESPACE']}:document",
      description: @document.description,
      image: asset_url('logo_myschool_blue_beta.png'),
      url: url_for(@document),
    }
  end

  def duplicate
    authorize @document

    @duplicated_document = @document.dup
    @duplicated_document.user = current_user
    @duplicated_document.school = nil
    @duplicated_document.group = nil

    CopyCarrierwaveFile::CopyFileService.new(@document, @duplicated_document, :file).set_file
    
    if @duplicated_document.save
      redirect_to @duplicated_document, notice: "Document has been copied to your profile"
    else
      redirect_to :back, notice: "Unable to duplicate document"
    end

  end

  def destroy
    authorize @document
    @document.delete

    if @school.present?
      redirect_to documents_school_path(@school), notice: "Document deleted."
    elsif @group.present?
      redirect_to documents_group_path(@group), notice: "Document deleted."
    else
      redirect_to documents_stuff_user_path(current_user, filter: 'profile'), notice: 'Document deleted.'
    end

  end

  def repost
    create_activity
    redirect_to :back, notice: 'Document reposted to activity feed.'
  end

  private

    def document_params
      params.require(:document).permit(:file, :file_cache, :remote_file_url, :school_id, :group_id, :name, :year, :identifier, :description, :existing_document_id)
    end

    def set_document_objects
      @document = Document.find(params[:id])
      @school = @document.school if @document.school.present?
      @group = @document.group if @document.group.present?
    end

    def set_commentable
      @commentable = @document
      @comment = Comment.new
      @comments = @commentable.comments
    end

    def create_activity
      @document.create_activity key: "document.create", owner: current_user, recipient: @document.group || @document.school, role: @document.role
    end

    def validate_group_and_school_permissions
      if @document.school && !SchoolPolicy.new(current_user, @document.school).new_post?
        raise Pundit::NotAuthorizedError
      elsif @document.group && !GroupPolicy.new(current_user, @document.group).new_post?
        raise Pundit::NotAuthorizedError
      end
    end

    def resolve_new_document_redirect
      if @document.group.present?
        redirect_to documents_stuff_group_path(@document.group, filter: 'all'), notice: 'Document uploaded.'
      elsif @document.school.present?
        redirect_to documents_stuff_school_path(@document.school, filter: 'all'), notice: 'Document uploaded.'
      else
        redirect_to documents_stuff_user_path(@document.user, filter: 'profile'), notice: 'Document uploaded.'
      end
    end

end
