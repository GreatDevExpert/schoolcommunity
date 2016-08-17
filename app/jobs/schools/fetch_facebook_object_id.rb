class Schools::FetchFacebookObjectId < ActiveJob::Base

  def perform(school_id, user_id)
    @school = School.find(school_id)
    return if @school.facebook_object_id.present?
    @user = User.find(user_id)
    FacebookGraph.new(@user.facebook_token).pull_education_data(@user)
    @user.schools.each do |school|
      Schools::FetchAddress.perform_later(school.id, @user.facebook_token)
    end
  end

end