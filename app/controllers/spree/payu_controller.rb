module Spree
  class PayuController < Spree::BaseController
    protect_from_forgery except: [:notify, :continue]

    def notify
      response = OpenPayU::Order.retrieve(params[:order][:orderId])
      order_info = response.parsed_data['orders']['orders'].first
      order = Spree::Order.find(order_info['extOrderId'])
      payment = order.payments.last

      unless payment.completed? || payment.failed?
        case order_info['status']
        when 'CANCELED', 'REJECTED'
          payment.failure!
        when 'COMPLETED'
          payment.complete!
        end
      end

      render json: OpenPayU::Order.build_notify_response(response.req_id)
    end
  end
end
