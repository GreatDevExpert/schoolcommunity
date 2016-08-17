class UpdateBoxViewStatusJob < ActiveJob::Base
  queue_as :default

  THUMBNAIL_HEIGHT = 768
  THUMBNAIL_WIDTH = 768

  def perform(document)
    status = BoxView::Document.status(document.box_view_uuid)
    case status['status']
    when 'done'
      document.box_view_status = 'success'
      document.save!

      UpdateBoxViewThumbnailJob.set(wait: 30.seconds).perform_later(document)
    when 'queued', 'processing'
      UpdateBoxViewStatusJob.set(wait: 30.seconds).perform_later(document)
    when 'error'
      document.box_view_status = 'error'
      document.save!
    else
      raise "Unexpected status: #{status['status']}"
    end
  end
end
