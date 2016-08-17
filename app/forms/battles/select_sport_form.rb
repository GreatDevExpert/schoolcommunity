class Battles::SelectSportForm < Reform::Form
  property :sport_category
  property :sport_name
  property :team_level

  validates :sport_category,  presence: true
  validates :sport_name,  presence: true

end
