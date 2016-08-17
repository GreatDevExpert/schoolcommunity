class UpdateBoxViewThumbnailJob < ActiveJob::Base
  queue_as :default

  THUMBNAIL_HEIGHT = 768
  THUMBNAIL_WIDTH = 768

  def perform(document)
    thumbnail_data = BoxView::Download.thumbnail(document.box_view_uuid, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)
    tempfile = Tempfile.new(["thumbnail", "jpg"])
    begin
      tempfile.binmode
      tempfile.write thumbnail_data
      tempfile.close

      document.document_preview = tempfile
      document.save!
    ensure
      tempfile.close
      tempfile.unlink
    end
  end
end
