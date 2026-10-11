require "rails_helper"

RSpec.describe ShippingCalculator do
  describe "#calculate" do
    {
      10_000 => 0,
      5_001 => 0,
      5_000 => 0,
      4_999 => 500,
      3_000 => 500,
      1 => 500
    }.each do |amount, fee|
      it "SHIP-01/02 #{amount}円なら送料は#{fee}円になる" do
        expect(described_class.new(order_amount: amount).calculate).to eq(fee)
      end
    end

    [ 0, -1, -100 ].each do |amount|
      it "SHIP-03 #{amount}円なら例外を発生させる" do
        expect {
          described_class.new(order_amount: amount).calculate
        }.to raise_error(ArgumentError, "Invalid amount")
      end
    end
  end
end
