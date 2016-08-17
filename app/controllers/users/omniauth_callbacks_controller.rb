class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      @facebook_token = request.env["omniauth.auth"].credentials.token
      set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
      @user.update_attribute(:facebook_token, @facebook_token)

      UserLogin.new(@user).complete_login
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url, alert: "Login Unsuccessful. Error Message: #{@user.errors.full_messages}"
      AdminMailer.error_alert(@user.errors.full_messages).deliver_now
    end
  end
end
