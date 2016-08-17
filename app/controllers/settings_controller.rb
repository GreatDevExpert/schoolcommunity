class SettingsController < ApplicationController
  before_action :authenticate_user!

  def edit
    @settings = current_user.settings(:settings)

    # Want to make sure this is an "edit" and not a "new"
    @settings.save! unless @settings.persisted?

    @form = SettingForm.new(@settings)
  end

  def update
    @settings = current_user.settings(:settings)
    @form = SettingForm.new(@settings)

    if @form.validate(params[:setting])
      flash[:success] = "Your settings have been updated"
      @form.save
    else
      flash[:error] = "Unable to update settings"
    end
    redirect_to edit_setting_path('my')
  end
end
