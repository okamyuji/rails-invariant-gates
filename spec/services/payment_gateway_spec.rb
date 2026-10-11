require "rails_helper"

RSpec.describe PaymentGateway do
  describe ".charge" do
    it "決済結果として状態と金額を返す" do
      expect(described_class.charge(1000)).to eq(status: "succeeded", amount: 1000)
    end
  end
end
