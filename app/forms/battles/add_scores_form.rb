class Battles::AddScoresForm < Reform::Form

  property :opponent_score
  property :challenger_score
  property :game_winner_kind
  property :score_detail

  validates :game_winner_kind,  presence: true

end