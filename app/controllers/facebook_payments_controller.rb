class FacebookPaymentsController < ApplicationController
  before_action :authenticate_user!
  skip_before_filter :verify_authenticity_token, only: :new # For embedding in facebook iframe

  def new
    @facebook_payment = FacebookPayment.create!(user: current_user)
  end

  def create
    @facebook_payment = FacebookPayment.find(params[:id])
    if params[:quantity]
      @facebook_payment.update(amount: params[:quantity])
    end
    if @facebook_payment.may_set_pending?
      @facebook_payment.set_pending!
    end

    redirect_to stored_location, notice: 'Your payment is being processed and your scrilla will be deposited to your account shortly'

    
    # redirect_to stored_location, notice: 'Your payment is being processed and your scrilla will be deposited to your account shortly'
  end

  def index
    @facebook_payments = FacebookPayment.where(user: current_user).where(aasm_state: [:pending, :succeeded, :failed]).order('created_at DESC')
  end
end
