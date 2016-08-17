class Opengraph::FacebookController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def scrilla
    render layout: false
  end

  def test_payment_object_subscription
    challenge = params['hub.challenge']
    render plain: challenge
  end

  def payment_object_subscription
    facebook_update_processor = FacebookUpdateProcessor.new(params['object'], params['entry'])
    facebook_update_processor.process
    head :ok
  end
end
