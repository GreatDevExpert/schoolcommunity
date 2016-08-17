class ScrillaTransfersController < ApplicationController
  def new
    raise Pundit::NotAuthorizedError unless ScrillaTransfersPolicy.new(current_user, nil).new?

    @scrilla_transfer = ScrillaTransfer.new
    if params[:scrilla_request]
      scrilla_request = ScrillaRequest.find(params[:scrilla_request])
      if scrilla_request
        @scrilla_transfer.recipient = scrilla_request.sender
        @scrilla_transfer.amount = scrilla_request.amount
      end
    elsif params[:recipient_id]
      @scrilla_transfer.recipient_id = params[:recipient_id]
    end
  end

  def create
    raise Pundit::NotAuthorizedError unless ScrillaTransfersPolicy.new(current_user, nil).create?

    @scrilla_transfer = ScrillaTransfer.new(scrilla_transfer_params)
    @scrilla_transfer.sender = current_user
    @scrilla_transfer.transfer_type = 'transfer'

    if @scrilla_transfer.save
      @scrilla_transfer.complete!
      flash[:notice] = 'Your transfer has been completed'
      redirect_to user_scrilla_transfers_path(current_user)
    else
      flash[:notice] = 'An error occured during the transfer'
      render :new
    end
  end

  def index
    @user = User.find(params[:user_id])
    raise Pundit::NotAuthorizedError unless ScrillaTransfersPolicy.new(current_user, @user).index?

    @scrilla_transfers = @user.scrilla_transfers.order('created_at DESC').page(params[:page]).per(10)
  end

  private
    def scrilla_transfer_params
      params.require(:scrilla_transfer).permit(:recipient_id, :amount, :message)
    end
end
