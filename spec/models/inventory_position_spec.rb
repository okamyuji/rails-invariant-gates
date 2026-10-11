require "rails_helper"

# describe の ID は記事の契約表（INV/PRE/POST/ERR）に対応する。
RSpec.describe InventoryPosition do
  def build(total:, available:, reserved:)
    described_class.new(total_stock: total, available_stock: available, reserved_stock: reserved)
  end

  let(:inventory) { build(total: 10, available: 10, reserved: 0) }

  describe ".new" do
    it "POST-03 整合性のある在庫状態を生成でき、凍結されている" do
      position = build(total: 10, available: 7, reserved: 3)

      aggregate_failures do
        expect(position.total_stock).to eq(10)
        expect(position.available_stock).to eq(7)
        expect(position.reserved_stock).to eq(3)
        expect(position).to be_frozen
      end
    end

    it "INV-01 すべて0の在庫状態を生成できる" do
      expect(build(total: 0, available: 0, reserved: 0).total_stock).to eq(0)
    end

    describe "INV-01 在庫数は負にならない" do
      [
        { total: 10, available: -1, reserved: 11 },
        { total: 10, available: 11, reserved: -1 },
        { total: -1, available: 0, reserved: -1 }
      ].each do |stocks|
        it "#{stocks}を拒否する" do
          expect { build(**stocks) }.to raise_error(InventoryPosition::InvalidState)
        end
      end
    end

    describe "INV-02 総在庫は内訳の合計と一致する" do
      it "合計が足りない状態を拒否する" do
        expect { build(total: 10, available: 7, reserved: 2) }.to raise_error(InventoryPosition::InvalidState)
      end

      it "合計が超える状態を拒否する" do
        expect { build(total: 10, available: 7, reserved: 4) }.to raise_error(InventoryPosition::InvalidState)
      end
    end

    describe "INV-03 在庫数は整数である" do
      [
        { total: 10, available: 7.5, reserved: 2.5 },
        { total: 10.0, available: 7, reserved: 3 },
        { total: 10, available: 7, reserved: nil }
      ].each do |stocks|
        it "#{stocks}を拒否する" do
          expect { build(**stocks) }.to raise_error(InventoryPosition::InvalidState)
        end
      end
    end
  end

  describe "#reserve" do
    describe "POST-01/02/03 指定数量だけ移動し、元の値は変えない" do
      [ 1, 3, 9, 10 ].each do |quantity|
        it "#{quantity}個の引当で数量が正しく移動し、総在庫も保存される" do
          before = inventory

          after = inventory.reserve(quantity)

          aggregate_failures do
            expect(after.available_stock).to eq(before.available_stock - quantity)
            expect(after.reserved_stock).to eq(before.reserved_stock + quantity)
            expect(after.total_stock).to eq(10)
            expect(after.available_stock + after.reserved_stock).to eq(after.total_stock)
            expect(before.available_stock).to eq(10)
            expect(before.reserved_stock).to eq(0)
          end
        end
      end

      it "複数回の引当後も不変条件を維持する" do
        position = build(total: 100, available: 100, reserved: 0)

        [ 10, 20, 5, 15, 50 ].each do |quantity|
          previous = position
          position = position.reserve(quantity)

          aggregate_failures "quantity=#{quantity}" do
            expect(position.available_stock).to eq(previous.available_stock - quantity)
            expect(position.reserved_stock).to eq(previous.reserved_stock + quantity)
            expect(position.available_stock + position.reserved_stock).to eq(100)
          end
        end

        expect([ position.available_stock, position.reserved_stock ]).to eq([ 0, 100 ])
      end
    end

    describe "PRE-01 引当数量は正の整数" do
      [ 0, -1, 2.5, nil, "3" ].each do |quantity|
        it "#{quantity.inspect}個の引当を拒否し、元の状態を維持する" do
          expect { inventory.reserve(quantity) }.to raise_error(InventoryPosition::InvalidQuantity)

          expect([ inventory.available_stock, inventory.reserved_stock ]).to eq([ 10, 0 ])
        end
      end
    end

    describe "PRE-02 引当数量は引当可能在庫以下" do
      it "在庫を超える引当を拒否し、元の状態を維持する" do
        expect { inventory.reserve(11) }.to raise_error(InventoryPosition::InsufficientStock)

        expect([ inventory.available_stock, inventory.reserved_stock ]).to eq([ 10, 0 ])
      end
    end
  end
end
