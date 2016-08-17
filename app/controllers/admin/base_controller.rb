class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_super_admin


  private
    def verify_super_admin
      unless current_user.super_admin?
        raise Pundit::NotAuthorizedError
      end
    end
end