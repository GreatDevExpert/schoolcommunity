class Reindex < ActiveJob::Base
  queue_as :reindex

  def perform(item_to_reindex)
    if item_to_reindex
      Sunspot.index! item_to_reindex
    end
  end

end
