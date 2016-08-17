class Address < ActiveRecord::Base
  belongs_to :school

  validates :city, presence: true
  validates :state, presence: true
  validates :postal_code, presence: true
  validates_format_of :postal_code, :with => /\A\d{5}(-\d{4})?\z/, :message => "should be in the form 12345 or 12345-1234"


  STATE_CODES = %w(AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA
  MD ME MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX UT VA
  VT WA WI WV WY)

  def full_address
    if line_one.present?
    "#{line_one}, #{city}, #{state} #{postal_code}"
    else
      city_state_zip
    end
  end

  def city_state
    "#{city}, #{state}"
  end

  def city_state_zip
    "#{city}, #{state} #{postal_code}"
  end

  def map_url
    "https://maps.google.com?q=#{school.name} #{city} #{state} #{postal_code}"
  end

end
