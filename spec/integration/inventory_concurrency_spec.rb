require "rails_helper"

RSpec.describe "在庫引当の同時実行", type: :model do
  # 別スレッドのDB接続から見えるように、この例だけは実際にコミットする。
  self.use_transactional_tests = false

  let!(:product_id) do
    Product.create!(total_stock: 1, available_stock: 1, reserved_stock: 0).id
  end

  after { Product.where(id: product_id).delete_all }

  it "CON-01 在庫1個に2つの接続から同時に引き当てても成功は1件だけになる" do
    ready = Queue.new
    go = Queue.new

    threads = Array.new(2) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          product = Product.find(product_id)
          ready << true
          go.pop
          InventoryReservationService.new(product: product).call(quantity: 1)
          :reserved
        rescue InventoryPosition::InsufficientStock
          :insufficient
        end
      end
    end

    2.times { ready.pop }
    2.times { go << true }
    results = threads.map(&:value)

    product = Product.find(product_id)
    aggregate_failures do
      expect(results.sort).to eq(%i[insufficient reserved])
      expect([ product.available_stock, product.reserved_stock ]).to eq([ 0, 1 ])
    end
  end
end
