require "rails_helper"

RSpec.describe Product, type: :model do
  def build_product(total: 10, available: 10, reserved: 0)
    described_class.new(total_stock: total, available_stock: available, reserved_stock: reserved)
  end

  describe "バリデーション" do
    it "INV-02 整合性のある在庫は有効" do
      expect(build_product(total: 10, available: 7, reserved: 3)).to be_valid
    end

    it "INV-01 すべて0の在庫は有効" do
      expect(build_product(total: 0, available: 0, reserved: 0)).to be_valid
    end

    it "INV-01 在庫数が1の在庫は有効" do
      expect(build_product(total: 1, available: 1, reserved: 0)).to be_valid
    end

    it "INV-01 負の在庫数を拒否する" do
      product = build_product(total: 10, available: -1, reserved: 11)

      expect(product).not_to be_valid
      expect(product.errors[:available_stock]).to include("must be greater than or equal to 0")
    end

    it "INV-03 整数以外の在庫数を拒否する" do
      product = build_product(total: 10, available: 7.5, reserved: 2.5)

      expect(product).not_to be_valid
      expect(product.errors[:available_stock]).to include("must be an integer")
    end

    it "INV-02 総在庫と内訳が一致しない状態を拒否する" do
      product = build_product(total: 10, available: 7, reserved: 2)

      expect(product).not_to be_valid
      expect(product.errors[:base]).to eq([ "Stock conservation violated" ])
    end

    it "INV-03 在庫数が欠けているときは保存則の検証を飛ばす" do
      product = build_product(total: 10, available: nil, reserved: 0)

      expect(product).not_to be_valid
      expect(product.errors[:base]).to be_empty
    end
  end

  describe "#inventory_position" do
    it "MAP-01 保存されている在庫数からInventoryPositionを作る" do
      position = build_product(total: 10, available: 7, reserved: 3).inventory_position

      expect(position).to be_an_instance_of(InventoryPosition)
      expect([ position.total_stock, position.available_stock, position.reserved_stock ]).to eq([ 10, 7, 3 ])
    end
  end

  describe "DB制約" do
    let!(:product) { Product.create!(total_stock: 10, available_stock: 10, reserved_stock: 0) }

    it "INV-01 update_columnsでバリデーションを飛ばしても負の在庫はCHECK制約で拒否される" do
      expect {
        product.update_columns(available_stock: -1, reserved_stock: 11)
      }.to raise_error(ActiveRecord::CheckViolation, /products_available_stock_non_negative/)

      product.reload

      expect([ product.available_stock, product.reserved_stock ]).to eq([ 10, 0 ])
    end

    it "INV-02 update_columnsでバリデーションを飛ばしても保存則に反する在庫はCHECK制約で拒否される" do
      expect {
        product.update_columns(available_stock: 7, reserved_stock: 2)
      }.to raise_error(ActiveRecord::CheckViolation, /products_stock_conservation/)
    end
  end
end
