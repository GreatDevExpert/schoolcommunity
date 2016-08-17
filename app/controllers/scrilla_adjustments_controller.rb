class ScrillaAdjustmentsController < ApplicationController
  def new
    @scrilla_transfer = ScrillaTransfer.new
    if params[:recipient_id]
      @scrilla_transfer.recipient_id = params[:recipient_id]
    end
    @form = ScrillaAdjustmentForm.new(@scrilla_transfer)
    raise Pundit::NotAuthorizedError unless ScrillaAdjustmentPolicy.new(current_user, @scrilla_transfer).new?
  end

  def create
    @scrilla_transfer = ScrillaTransfer.new
    @scrilla_transfer.recipient_id = scrilla_adjustment_params[:recipient_id]
    @scrilla_transfer.amount = parse_amount(scrilla_adjustment_params[:amount])
    @scrilla_transfer.message = scrilla_adjustment_params[:message]

    @scrilla_transfer.transfer_type = 'admin_adjustment'

    raise Pundit::NotAuthorizedError unless ScrillaAdjustmentPolicy.new(current_user, @scrilla_transfer).create?

    if @scrilla_transfer.amount < 0
      @scrilla_transfer.invert!
    end

    if @scrilla_transfer.save
      @scrilla_transfer.complete!
      # when deducting scrilla, we invert the sender and user. This means one of these will be nil. The following line ensures we are redirecting to the right person.
      user = @scrilla_transfer.recipient || @scrilla_transfer.sender
      redirect_to user_scrilla_transfers_path(user), notice: 'Your transfer has been completed'
    else
      @form = ScrillaAdjustmentForm.new(@scrilla_transfer)
      flash.now[:alert] = "Invalid adjustment"
      render :new
    end
  end

  private
    def scrilla_adjustment_params
      params.require(:scrilla_adjustment).permit(:recipient_id, :amount, :message)
    end

    def parse_amount(amount)
      rounded = amount.split(".")[0]
      rounded.gsub(/[^\d-]/, '').to_i
    end
end
