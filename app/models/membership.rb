class Membership < ActiveRecord::Base
  after_commit :reindex_group #so member_count and is updated

  belongs_to :user
  belongs_to :group
  has_many :comments, as: :commentable, dependent: :destroy

  STANDARD_ROLES = [
    ['Monitor', 'monitor'],
    ['Standard', 'standard'],
    ['Invited', 'invited'],
    ['Awaiting Approval', 'awaiting_approval'],
  ]

  include PublicActivity::Model

  searchable do
    text :full_name do
      user.full_name unless user.blank?
    end
    string :role_name do
      role
    end
    integer :group_id

    string :publicly_searchable do
      if user.blank?
        'false'
      else
        'true'
      end
    end
  end

  def notification_users
    [user]
  end

  private

    def reindex_group
      Reindex.perform_later(user)
      Reindex.perform_later(group)
    end

end
