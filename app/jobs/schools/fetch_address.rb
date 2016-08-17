class Schools::FetchAddress < ActiveJob::Base

  def perform(school_id, user_facebook_token)
    @school = School.unscoped.find(school_id)
    return if @school.address.present?
    ActiveRecord::Base.connection_pool.with_connection do
      school_hashie = FacebookGraph.new(user_facebook_token).pull_school_hashie(@school.facebook_object_id)
      location_hashie = school_hashie.location
      @school.add_fb_address(location_hashie)
    end
  end

end