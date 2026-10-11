require "rails_helper"

RSpec.describe InventoryReservationService do
  describe "#call" do
    let(:product) do
      Product.create!(
        total_stock: 10,
        available_stock: 10,
        reserved_stock: 0
      )
    end

    subject(:service) do
      described_class.new(product: product)
    end

    def persisted_stocks
      product.reload.attributes.slice("total_stock", "available_stock", "reserved_stock")
    end

    it "引当後も在庫の不変条件を維持してDBに保存する" do
      expect(service.call(quantity: 3)).to be(true)

      expect(persisted_stocks).to eq(
        "total_stock" => 10, "available_stock" => 7, "reserved_stock" => 3
      )
    end

    it "保存前の値ではなくロックして読み直した値から計算する" do
      Product.where(id: product.id).update_all(available_stock: 4, reserved_stock: 6)

      service.call(quantity: 3)

      expect(persisted_stocks).to eq(
        "total_stock" => 10, "available_stock" => 1, "reserved_stock" => 9
      )
    end

    it "在庫不足の場合はDBの状態を変更しない" do
      before = persisted_stocks

      expect {
        service.call(quantity: 11)
      }.to raise_error(InventoryPosition::InsufficientStock)

      expect(persisted_stocks).to eq(before)
    end

    it "保存に失敗したら握りつぶさずに例外を伝える" do
      allow(product).to receive(:valid?).and_return(false)

      expect {
        service.call(quantity: 3)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "不正な数量の場合はDBの状態を変更しない" do
      before = persisted_stocks

      expect {
        service.call(quantity: 0)
      }.to raise_error(InventoryPosition::InvalidQuantity)

      expect(persisted_stocks).to eq(before)
    end
  end
end
