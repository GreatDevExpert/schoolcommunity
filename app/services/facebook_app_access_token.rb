class FacebookAppAccessToken
  def app_access_token
    @app_access_token ||= build_app_access_token
  end

  private
    def build_app_access_token
      # https://github.com/arsduo/koala#oauth
      oauth = Koala::Facebook::OAuth.new(ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'])
      oauth.get_app_access_token
    end
end
