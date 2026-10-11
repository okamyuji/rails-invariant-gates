require "rails_helper"

RSpec.describe PaymentService do
  describe "#charge" do
    it "決済に成功する" do
      service = described_class.new(amount: 1000)

      expect(service.charge).to be_truthy
    end
  end
end
