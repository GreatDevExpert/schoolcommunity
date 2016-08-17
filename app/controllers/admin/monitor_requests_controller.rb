class Admin::MonitorRequestsController < ApplicationController
  def index
    query = MonitorRequestsQuery.new(current_user)
    @groups = query.groups
    @schools = query.schools
  end
end
