require "rails_helper"

RSpec.describe Order, type: :model do
  describe "#cancellable?" do
    it "pendingならキャンセルできる" do
      order = described_class.new(status: :pending)

      expect(order.cancellable?).to be(true)
    end

    it "shippedならキャンセルできない" do
      order = described_class.new(status: :shipped)

      expect(order.cancellable?).to be(false)
    end
  end
end
