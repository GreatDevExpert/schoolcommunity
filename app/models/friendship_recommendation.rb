class FriendshipRecommendation < ActiveRecord::Base
  belongs_to :user
  belongs_to :recommended_friend, class_name: 'User'

  validates_uniqueness_of :user_id, :scope => :recommended_friend_id

  searchable do
    text :full_name do
      recommended_friend.full_name unless recommended_friend.nil?
    end
    text :schools do
      recommended_friend.schools.collect(&:name) unless recommended_friend.nil?
    end
    text :groups do
      recommended_friend.groups.collect(&:name) unless recommended_friend.nil?
    end
    text :full_address do
      recommended_friend.full_address unless recommended_friend.nil?
    end

    text :fellowship_roles do
      recommended_friend.fellowships.collect(&:role) unless recommended_friend.nil?
    end

    integer :user_id
    integer :recommended_friend_id
  
    string :publicly_searchable do
      if recommended_friend.nil?
        'false'
      elsif recommended_friend.visibility !=  'visible'
        'false'
      elsif recommended_friend.state != 'active'
        'false'
      else
        'true'
      end
    end

  end
end
