require "rails_helper"

RSpec.describe OrderCancellationService do
  describe "#call" do
    it "キャンセルできる注文ならtrueを返す" do
      order = Order.create!(status: :pending)

      service = described_class.new(order: order)

      expect(service.call).to eq(true)
    end
  end
end
