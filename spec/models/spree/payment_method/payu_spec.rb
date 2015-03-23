require 'spec_helper'

RSpec.describe Spree::PaymentMethod::Payu, type: :model do
  let(:instance) { described_class.new }

  describe "#payment_profiles_supported?" do
    subject { instance.payment_profiles_supported? }
    specify { is_expected.to be false }
  end

  describe "#source_required?" do
    subject { instance.source_required? }
    specify { is_expected.to be false }
  end

  describe "#success?" do
    subject { instance.success? }
    specify { is_expected.to be true }
  end

  describe "#cancel" do
    subject { instance.cancel }
    specify { is_expected.to be nil }
  end

  describe "#authorization" do
    subject { instance.authorization }
    specify { is_expected.to be instance }
  end

  describe "#credit" do
    subject { instance.credit }
    specify { is_expected.to be instance }
  end
end
