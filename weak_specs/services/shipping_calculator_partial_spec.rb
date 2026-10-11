require "rails_helper"

RSpec.describe ShippingCalculator do
  describe "#calculate" do
    context "注文金額が5,000円以上の場合" do
      it "送料が無料になる" do
        calculator = described_class.new(order_amount: 10_000)

        expect(calculator.calculate).to eq(0)
      end
    end

    context "注文金額が5,000円未満の場合" do
      it "送料が500円になる" do
        calculator = described_class.new(order_amount: 3_000)

        expect(calculator.calculate).to eq(500)
      end
    end

    context "注文金額が不正な場合" do
      it "例外を発生させる" do
        calculator = described_class.new(order_amount: -100)

        expect {
          calculator.calculate
        }.to raise_error(ArgumentError)
      end
    end
    context "注文金額が5,000円ちょうどの場合" do
      it "送料が無料になる" do
        calculator = described_class.new(order_amount: 5_000)

        expect(calculator.calculate).to eq(0)
      end
    end

    context "注文金額が0円の場合" do
      it "例外を発生させる" do
        calculator = described_class.new(order_amount: 0)

        expect {
          calculator.calculate
        }.to raise_error(
          ArgumentError,
          "Invalid amount"
        )
      end
    end
  end
end
