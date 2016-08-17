class FacebookUpdateProcessor
  def initialize(object, entry)
    @object    = object
    @entry     = entry
    @app_token = FacebookAppAccessToken.new.app_access_token
  end

  def process
    case @object
    when 'payments'
      process_payments
    else
      fail 'Unhandled process type'
    end
  end

  private
    def process_payments
      id = @entry.first['id']

      # Fetch the object from the graph
      graph = Koala::Facebook::API.new(@app_token)
      graph_payment = graph.get_object(id)

      facebook_payment = FacebookPayment.find_by(uuid: graph_payment['request_id'])
      fail 'Unable to find facebook payment' unless facebook_payment

      graph_payment['items'].each do |item|
        type     = item['type']
        product  = item['product']
        quantity = item['quantity']

        fail unless type == 'IN_APP_PURCHASE'

        transfer = ScrillaTransfer.create!(recipient: facebook_payment.user, amount: quantity, transfer_type: 'facebook_purchase', message: 'Thank you for your purchase')
        transfer.complete!
      end
      facebook_payment.complete_successfully!
    end
end
