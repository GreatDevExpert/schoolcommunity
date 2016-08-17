# Helper to allow setting the fellowship to set the school
module FellowshipAssignable
 extend ActiveSupport::Concern

  attr_reader :role
  def fellowship=(fellowship)
    self.school = fellowship.school
    @role = fellowship.role
  end
end
