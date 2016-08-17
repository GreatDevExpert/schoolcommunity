class GenerateBoxViewUuidJob < ActiveJob::Base
  queue_as :default

  THUMBNAIL_HEIGHT = 768
  THUMBNAIL_WIDTH = 768

  def perform(document)
    document.box_view_uuid = BoxView::Document.upload(document.file.url, nil, "#{THUMBNAIL_WIDTH}x#{THUMBNAIL_HEIGHT}")
    document.box_view_status = 'pending'
    document.save!

    UpdateBoxViewStatusJob.set(wait: 15.seconds).perform_later(document)
  end
end
