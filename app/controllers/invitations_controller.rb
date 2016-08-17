class InvitationsController < ApplicationController
  def create
    @invitation = Invitation.new
    @invitation.sender = current_user
    @invitation.recipients = User.where(id: invitation_params[:recipients])
    @invitation.message = invitation_params[:message]
    @invitation.target = Identifiable.from_identifier(invitation_params[:target])

    if @invitation.valid?
      @invitation.save
      redirect_to :back, notice: 'Your invitations have been sent'
    end
  end

  private
  def invitation_params
    params.require(:invitation).permit(:message, :target, recipients: [])
  end
end
