require "rails_helper"

RSpec.describe InventoryPosition do
  describe "#reserve" do
    let(:inventory) do
      described_class.new(
        total_stock: 10,
        available_stock: 10,
        reserved_stock: 0
      )
    end

    it "引当後も総在庫が保存される" do
      result = inventory.reserve(3)

      expect(
        result.available_stock + result.reserved_stock
      ).to eq(result.total_stock)
    end
  end
end
