class Post < ActiveRecord::Base
  include Identifiable
  include Monitorable
  include FellowshipAssignable

  belongs_to :user, unscoped: true
  belongs_to :school
  belongs_to :group
  has_many :comments, as: :commentable, dependent: :destroy

  validates :content, presence: true

  include PublicActivity::Model

  def notification_users
    [user]
  end
  
  def to_param
    [id, content.truncate(30).parameterize].join("-")
  end
end
