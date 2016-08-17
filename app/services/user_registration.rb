class UserRegistration
  attr_accessor :facebook_request_ids

  def initialize(user)
    @user = user
  end

  def complete_registration
    @user.initialize_scrilla_balance
    @user.create_activity key: 'user.create', owner: @user
    @user.fellowships.each do |fellowship|
      fellowship.create_activity key: 'fellowship.create', owner: @user, recipient: fellowship.school
    end

    if @facebook_request_ids
      @facebook_request_ids.split(',').each do |request_id|
        facebook_request = FacebookRequest.find_by_request_id(request_id)
        if facebook_request && facebook_request.request_type == 'invitation'
          Friendship.create(user: @user, friend: facebook_request.user)
          Friendship.create(user: facebook_request.user, friend: @user)
          ScrillaTransfer.create(recipient: facebook_request.user, amount: ScrillaBalance::MEMBER_REFERRAL_AMOUNT, transfer_type: 'member_referral').complete!
        end
      end
    end
    
    UserRegistrationNotification.new(recipient: @user).notify
  end
end
