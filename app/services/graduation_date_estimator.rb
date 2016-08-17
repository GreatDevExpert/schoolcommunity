# Very simple calculation right now. We can easily make this more complicated
# if desired
class GraduationDateEstimator
  attr_accessor :user, :school, :fellowship_type

  def initialize(user:, school:, fellowship_type:)
    @user = user
    @school = school
    @fellowship_type = fellowship_type
  end

  def graduation_date
    if fellowship_type == 'student'
      Date.today + 3.years
    else
      Date.today - 3.years
    end
  end
end
