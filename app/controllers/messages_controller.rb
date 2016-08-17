class MessagesController < ApplicationController
  before_action :load_user, only: [:new, :create]

  def new
    @message = Message.new(sender: current_user, recipient: @user)
  end

  def create
    @message = Message.new(message_params)
    @message.sender = current_user
    @message.recipient = @user
    if @message.save
      redirect_to :back, notice: "Your message has been sent"
    else
      render :new
    end
  end

  private
  def load_user
    @user = User.find(params[:user_id])
  end

  def message_params
    params.require(:message).permit(:recipient, :message)
  end
end
