require 'spec_helper'

RSpec.describe PayuOrder, type: :lib do
  describe "#params" do
    let(:order) { OrderWalkthrough.up_to(:payment) }
    let(:order_url) { "http://localhost:5252/order_url/1234" }
    let(:notify_url) { "http://localhost:5252/order_url/notify/1234" }
    let(:continue_url) { "http://localhost:5252/order_url/checkout/continue" }

    let(:current_store) { FactoryGirl.create(:store, name: "Mój Spree Sklep") }

    before do
      I18n.locale = :pl
      allow(OpenPayU::Configuration).to receive(:merchant_pos_id).and_return("145228")
      allow(Spree::Store).to receive(:current).and_return(current_store)
    end

    subject { described_class.params(order, "128.0.0.1", order_url, notify_url, continue_url)}

    it "returns well structured hash from real order" do
      expect(subject).to eq({
        merchant_pos_id: "145228",
        customer_ip: "128.0.0.1",
        ext_order_id: 1,
        description: "Zamowienie z Moj Spree Sklep",
        currency_code: "USD",
        total_amount: 2000,
        order_url: "http://localhost:5252/order_url/1234",
        notify_url: "http://localhost:5252/order_url/notify/1234",
        continue_url: "http://localhost:5252/order_url/checkout/continue",
        buyer: {
          email: "spree@example.com",
          phone: "555-555-0199",
          first_name: "John",
          last_name: "Doe",
          language: "PL",
          delivery: {
            street: "10 Lovely Street",
            postal_code: "35005",
            city: "Herndon",
            country_code: "US"
          }
        },
        products: [
          {
            name: order.line_items.first.product.name,
            unit_price: 1000,
            quantity: 1
          }
        ]
      })

      expect(subject[:products][0][:name]).to be_present
    end
  end
end
