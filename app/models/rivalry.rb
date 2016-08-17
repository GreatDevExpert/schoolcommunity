class Rivalry < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
  belongs_to :school
  belongs_to :rival_user, class_name: User, foreign_key: 'rival_user_id'

  validates :rival_user_id, uniqueness: { scope: :user_id,
    message: "you are already rivals" },
    unless: Proc.new { |a| a.rival_user_id.blank? }
  validates :group_id, uniqueness: { scope: :user_id,
    message: "you are already rivals" },
    unless: Proc.new { |a| a.group_id.blank? }
  validates :school_id, uniqueness: { scope: :user_id,
    message: "you are already rivals" },
    unless: Proc.new { |a| a.school_id.blank? }

  searchable do
    text :rival_user_name do
      rival_user.try(:full_name)
    end
    text :group_name do
      group.try(:name)
    end
    text :school_name do
      school.try(:name)
    end
    integer :user_id, stored: true
    integer :group_id, stored: true
    integer :rival_user_id, stored: true
    integer :school_id, stored: true
  end

  def grab_kind
    if group_id.present?
      'group'
    elsif school_id.present?
      'school'
    elsif rival_user_id.present?
      'rival_user'
    end
  end

end
