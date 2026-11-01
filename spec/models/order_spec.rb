require "rails_helper"

RSpec.describe Order, type: :model do
  describe "#cancellable?" do
    {
      pending: true,
      paid: true,
      shipped: false,
      cancelled: false
    }.each do |status, expected|
      it "ORD-01/02 #{status}の場合は#{expected}を返す" do
        order = described_class.new(status: status)

        expect(order.cancellable?).to eq(expected)
      end
    end

    it "ORD-01 未払いと分かった時点で支払い済みの確認を省く" do
      order = described_class.new(status: :pending)
      allow(order).to receive(:paid?)

      order.cancellable?

      expect(order).not_to have_received(:paid?)
    end
  end
end
