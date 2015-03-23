require 'spec_helper'

RSpec.describe Spree::PayuController, type: :controller do

  describe "POST /payu/notify" do
    let!(:order) { OrderWalkthrough.up_to(:address) }
    let(:payment_method) { FactoryGirl.create :payu_payment_method }
    let(:payment) { order.payments.last }
    # real response taken from VCR tape from OpenPayU implementation:
    # https://github.com/PayU/openpayu_ruby/blob/d751ec8db3e97dccf76edd79104f8ae9236e0cbd/spec/cassettes/retrieve_order.yml
    let(:order_retrieve_data) { {"req_id" => "PAYU-4321", "pageResponse"=>nil, "orders"=>{"orders"=>[{"shippingMethod"=>nil, "description"=>"New order", "fee"=>nil, "status"=>payu_status, "merchantPosId"=>"114207", "notifyUrl"=>"http://localhost/", "customerIp"=>"127.0.0.1", "extOrderId"=>order.id, "totalAmount"=>100, "buyer"=>nil, "orderCreateDate"=>1401265500678, "orderUrl"=>"http://localhost/", "validityTime"=>48000, "payMethod"=>nil, "products"=>{"products"=>[{"version"=>nil, "code"=>nil, "subMerchantId"=>nil, "categoryId"=>nil, "categoryName"=>nil, "quantity"=>1, "unitPrice"=>100, "extraInfo"=>nil, "weight"=>nil, "discount"=>nil, "name"=>"Mouse", "size"=>nil}]}, "currencyCode"=>"PLN", "orderId"=>"MHQ3MRZKSQ140528GUEST000P01"}]}, "version"=>"2.0", "redirectUri"=>nil, "status"=>{"code"=>nil, "codeLiteral"=>nil, "statusCode"=>"SUCCESS", "statusDesc"=>"Request processing successful", "severity"=>nil, "location"=>nil}, "resId"=>nil, "properties"=>nil} }
    let(:payu_status) { "NEW" }

    let(:fake_http_response) { double(:fake_response, code: "200", body: order_retrieve_data.to_json) }

    before do
      order.payments.create!(payment_method: payment_method, amount: order.total)

      allow(OpenPayU::Configuration).to receive(:merchant_pos_id).and_return("145278")
      allow(OpenPayU::Configuration).to receive(:signature_key).and_return("S3CRET_KEY")

      stub_request(:get, "https://145278:S3CRET_KEY@secure.payu.com/api/v2/orders/R1234").
        with(headers: {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
        to_return(status: 200, body: order_retrieve_data.to_json, headers: {})
    end

    subject { spree_post :notify, order: {orderId: "R1234"} }

    it "returns correct response for PayU" do
      subject
      expect(response.body).to eq(
        {"resId" => "PAYU-4321", "status" => {"statusCode" => "SUCCESS"}}.to_json
      )
    end

    context "when payment status is not failed nor complete" do
      before { payment.started_processing! }

      describe "when payu_status is COMPLETED" do
        let(:payu_status) { "COMPLETED" }

        it "completes payment" do
          subject
          expect(payment.reload).to be_completed
        end
      end

      describe "when payu_status is CANCELED" do
        let(:payu_status) { "CANCELED" }

        it "completes payment" do
          subject
          expect(payment.reload).to be_failed
        end
      end

      describe "when payu_status is REJECTED" do
        let(:payu_status) { "REJECTED" }

        it "completes payment" do
          subject
          expect(payment.reload).to be_failed
        end
      end
    end

    context "when payment status is complete" do
      describe "when payu_status is COMPLETED" do
        let(:payu_status) { "COMPLETED" }
        before do
          # mimicking completing payment
          payment.started_processing!
          payment.complete!
        end

        it "doesn't change payment" do
          payment_last_change_at = payment.updated_at
          subject
          expect(payment.reload).to be_completed
          expect(payment.updated_at).to eq(payment_last_change_at)
        end
      end
    end

    context "when payment status is failed" do
      describe "when payu_status is COMPLETED" do
        let(:payu_status) { "COMPLETED" }
        before do
          # mimicking failing payment
          payment.started_processing!
          payment.failure!
        end

        it "doesn't change payment" do
          payment_last_change_at = payment.updated_at
          subject
          expect(payment.reload).to be_failed
          expect(payment.updated_at).to eq(payment_last_change_at)
        end
      end
    end
  end
end


