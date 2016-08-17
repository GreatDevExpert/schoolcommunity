class Vote < ActiveRecord::Base
  belongs_to :battle
  belongs_to :user, unscoped: true

  validates :item, presence: true
  validates :user_id, presence: true
  validates :battle_id, presence: true
end
