class RegistrationsController < Devise::RegistrationsController
  def update
    @user = User.find(current_user.id)

    successfully_updated = if needs_password?(@user, params)
      @user.update_with_password(devise_parameter_sanitizer.sanitize(:account_update))
    else
      # remove the virtual current_password attribute
      # update_without_password doesn't know how to ignore it
      params[:user].delete(:current_password)
      @user.update_without_password(devise_parameter_sanitizer.sanitize(:account_update))
    end

    if successfully_updated
      save_avatar_to_stuff
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case their password changed
      sign_in @user, :bypass => true
      redirect_to after_update_path_for(@user)
    else
      render "edit"
    end
  end

  def new
    # we don't want to show the signup form yet. Everyone must go through Facebook login.
    render "devise/sessions/new"
  end

  private

    # check if we need password to update user data
    # ie if password or email was changed
    # extend this as needed
    def needs_password?(user, params)
      false
    end

    def after_update_path_for(resource)
      edit_user_registration_path
    end

    def save_avatar_to_stuff
      if params[:user][:avatar].present?
        Photo.create(user: current_user, year: DateTime.now, name: "Photo for #{current_user.full_name}", file: params[:user][:avatar])
      end
    end
end
