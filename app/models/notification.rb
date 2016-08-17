class Notification < ActiveRecord::Base
  belongs_to :recipient, polymorphic: true
  belongs_to :notifier, polymorphic: true

  def toggle_read_status!
    if read_at
      mark_as_unread!
    else
      mark_as_read!
    end
  end

  def mark_as_read!
    update(read_at: DateTime.now)
  end

  def mark_as_unread!
    update(read_at: nil)
  end

  def read?
    read_at ? true : false
  end

  def unread?
    !read?
  end

  def self.mark_all_as_read(recipient:)
    Notification.where(recipient: recipient).where(read_at: nil).update_all(read_at: DateTime.now)
  end
end
