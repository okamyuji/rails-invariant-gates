require "rails_helper"

RSpec.describe Order, type: :model do
  describe "#cancellable?" do
    {
      pending: true,
      paid: true,
      shipped: false,
      cancelled: false
    }.each do |status, expected|
      it "#{status}の場合は#{expected}を返す" do
        order = described_class.new(status: status)

        expect(order.cancellable?).to eq(expected)
      end
    end
  end
end
