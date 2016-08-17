class Battles::FinalizeGameTimeForm < Reform::Form
  property :description
  property :game_time
  property :start_date
  property :start_time
  property :battle_length

  validates :description, presence: true
  validates :battle_length, presence: true
  validates :start_date, presence: true
  validates :start_time, presence: true

  validate :ensure_game_time_is_in_the_future

  def ensure_game_time_is_in_the_future
    return if start_date.blank? && start_time.blank?
    begin
      # start_date is a string here, so I need to reformat it first
      # I also needed to reorder the date sting so this validation would pass
      # with the datepicker format we are using
      date_array = start_date.split('/')
      new_order = [2, 0, 1]
      reformated_start_date_string = (date_array.values_at *new_order).join('/')
      game_time = Time.zone.parse("#{reformated_start_date_string} #{start_time}")
      errors[:start_date] << "game time must be in the future" unless game_time > Time.current
      errors[:start_time] << "game time must be in the future" unless game_time > Time.current
    rescue ArgumentError
      errors[:start_date] << "invalid date"
    end
  end

end