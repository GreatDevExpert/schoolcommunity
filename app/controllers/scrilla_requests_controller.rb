class ScrillaRequestsController < ApplicationController
  def new
    @scrilla_request = ScrillaRequest.new
  end

  def create
    @scrilla_request = ScrillaRequest.create(scrilla_request_params)
    @scrilla_request.sender = current_user

    if @scrilla_request.save
      @scrilla_request.complete!

      flash[:success] = "Your request has been sent"
      redirect_to user_scrilla_transfers_path(current_user)
    else
      flash[:error] = "Unable to send your scrilla request"
      render :new
    end
  end

  private
    def scrilla_request_params
      params.require(:scrilla_request).permit(:recipient_id, :amount, :message)
    end
end
