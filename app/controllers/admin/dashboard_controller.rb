class Admin::DashboardController < Admin::BaseController

  def users
    authorize :dashboard, :users?
    @admin_search = params[:q]
    if @admin_search.present?
      @users =  User.unscoped.where("first_name ilike ? or last_name ilike ? or email ilike ? or state ilike ?", "%#{@admin_search}%", "%#{@admin_search}%", "%#{@admin_search}%", "%#{@admin_search}%")
    else
      @users = User.unscoped.all
    end

    @users = @users.order('current_sign_in_at DESC').page(params[:page]).per(30)
  end

end