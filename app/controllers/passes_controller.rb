class PassesController < ApplicationController
  before_action :set_battle
  before_action :set_pass, only: [:edit, :update]

  def new
    raise Pundit::NotAuthorizedError unless PassPolicy.new(current_user, @battle).new?
    @pass = @battle.passes.new
    render layout: false
  end

  def edit
    @amounts = Pass::AMOUNTS.select { |amount| amount.first >= @pass.amount}
    raise Pundit::NotAuthorizedError unless PassPolicy.new(current_user, @battle).edit?
    render layout: false
  end

  def create
    raise Pundit::NotAuthorizedError unless PassPolicy.new(current_user, @battle).create?
    @pass = current_user.passes.new(pass_params)
    @pass.battle = @battle
    
    transfer = ScrillaTransfer.new(sender: current_user, amount: @pass.amount, transfer_type: 'battle_pass')
  
    if @pass.valid? && transfer.valid?
      @pass.save
      transfer.save
      transfer.complete!
      redirect_to battle_path(@battle), notice: 'Battle Pass Acquired.'
    else
      render :new
    end
  end

  def update
    raise Pundit::NotAuthorizedError unless PassPolicy.new(current_user, @battle).update?

    new_charge = params[:pass][:amount].to_i - @pass.amount
    if new_charge > 0
      transfer = ScrillaTransfer.new(sender: current_user, amount: new_charge, transfer_type: 'battle_pass_upgrade')

      if transfer.valid? && @pass.update_attributes(update_pass_params)
        @pass.save
        transfer.save
        transfer.complete!
        redirect_to @battle, notice: 'Successfully upgraded battle pass.'
      else
        redirect_to @battle
      end
    else
      redirect_to @battle
    end
  end

  private

    def set_battle
      @battle = Battle.find(params[:battle_id])
    end

    def set_pass
      @pass = current_user.passes.find(params[:id])
    end

    def pass_params
      params.require(:pass).permit(:amount, :kind)
    end

    def update_pass_params
      params.require(:pass).permit(:amount)
    end


    def new_pass_purchase(amount)  
      transfer = ScrillaTransfer.create(sender: current_user, amount: amount, transfer_type: 'battle_purchase')
      raise "Invalid transfer" unless transfer.valid?
      transfer.complete
    end




end