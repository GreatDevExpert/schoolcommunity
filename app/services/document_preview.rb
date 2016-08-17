class DocumentPreview
  attr_accessor :document

  THEME = 'light'

  ICONS = {
    '.doc'  => 'fa-file-word-o',
    '.docx' => 'fa-file-word-o',
    '.xls'  => 'fa-file-excel-o',
    '.xlsx' => 'fa-file-excel-o',
    '.pdf'  => 'fa-file-pdf-o',
    '.ppt'  => 'fa-file-powerpoint-o',
  }
  DEFAULT_ICON = 'fa-file-o'
  ICON_SIZE = 'fa-10x'

  def initialize(document)
    @document = document
  end

  def icon_preview
    if @document.document_preview.url(:medium)
      ActionController::Base.helpers.image_tag(icon_preview_path)
    else
      icon("fa-5x")
    end
  end

  def icon_preview_path
    ActionController::Base.helpers.image_path(@document.document_preview.url(:small))
  end

  def small_preview
    if @document.document_preview.url(:medium)
      ActionController::Base.helpers.image_tag(@document.document_preview.url(:medium))
    else
      icon("fa-10x")
    end
  end

  def large_preview
    if document.box_view_status == 'success' && preview_url
      "<iframe class='document-preview' src='#{@preview_url}' allowfullscreen='allowfullscreen'></iframe>".html_safe
    elsif document.box_view_status == 'error'
      icon
    elsif document.box_view_status == 'pending'
      icon
    end
  end

  def preview_url
    if session_key
      @preview_url ||=  BoxView::Session.view_url(session_key, THEME)
    end
  end

  def download_url
    @document.file.url
  end

  private
  def session_key
    if document.box_view_uuid && document.box_view_status == 'success'
      @session_key ||= BoxView::Session.create(document.box_view_uuid, {is_downloadable: true, is_text_selectable: false})
    end
  end

  def icon(size = ICON_SIZE)
    extension = File.extname(document.file.url)
    icon = ICONS.fetch(extension, DEFAULT_ICON)
    "<div class='document-preview-icon'><i class='fa #{icon} #{size}'></i></div>".html_safe
  end
end
