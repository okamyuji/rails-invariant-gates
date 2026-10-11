require "rails_helper"
require_relative "../support/e2e_server"

RSpec.describe "POST /products/:product_id/reservations", type: :e2e do
  self.use_transactional_tests = false

  let!(:product) { Product.create!(total_stock: 10, available_stock: 10, reserved_stock: 0) }

  after { Product.where(id: product.id).delete_all }

  def stocks = product.reload.slice(:total_stock, :available_stock, :reserved_stock).transform_keys(&:to_s)

  it "在庫の範囲内なら201で引き当て、DBにも保存する" do
    response = e2e_post("/products/#{product.id}/reservations", quantity: 3)

    expected = { "total_stock" => 10, "available_stock" => 7, "reserved_stock" => 3 }
    aggregate_failures do
      expect(response).to eq([ 201, expected ])
      expect(stocks).to eq(expected)
    end
  end

  it "在庫と同じ数量は引き当てられる" do
    expect(e2e_post("/products/#{product.id}/reservations", quantity: 10).first).to eq(201)
  end

  it "文字列の数量も10進数として受け付ける" do
    expect(e2e_post("/products/#{product.id}/reservations", quantity: "010").last["reserved_stock"]).to eq(10)
  end

  it "在庫を超える数量は409を返し、DBを変えない" do
    response = e2e_post("/products/#{product.id}/reservations", quantity: 11)

    aggregate_failures do
      expect(response).to eq([ 409, { "error" => "Insufficient stock" } ])
      expect(stocks).to eq("total_stock" => 10, "available_stock" => 10, "reserved_stock" => 0)
    end
  end

  [ 0, -1, 1.5, "abc", nil, "1_0", "+3", " 3 " ].each do |quantity|
    it "数量#{quantity.inspect}は422を返し、DBを変えない" do
      response = e2e_post("/products/#{product.id}/reservations", { quantity: }.compact)

      aggregate_failures do
        expect(response).to eq([ 422, { "error" => "Invalid quantity" } ])
        expect(stocks).to eq("total_stock" => 10, "available_stock" => 10, "reserved_stock" => 0)
      end
    end
  end

  it "壊れたJSONは400を返し、DBを変えない" do
    response = e2e_post("/products/#{product.id}/reservations", "{bad json")

    aggregate_failures do
      expect(response).to eq([ 400, { "error" => "Invalid JSON" } ])
      expect(stocks).to eq("total_stock" => 10, "available_stock" => 10, "reserved_stock" => 0)
    end
  end

  it "IDの後ろに文字が付いたURLは404を返し、DBを変えない" do
    status, = e2e_post("/products/#{product.id}abc/reservations", quantity: 1)

    aggregate_failures do
      expect(status).to eq(404)
      expect(stocks).to eq("total_stock" => 10, "available_stock" => 10, "reserved_stock" => 0)
    end
  end

  it "存在しない商品は404を返す" do
    expect(e2e_post("/products/0/reservations", quantity: 1)).to eq([ 404, { "error" => "Not found" } ])
  end

  it "在庫1個に2本の要求を同時に送っても、成功は1件だけになる" do
    product.update!(total_stock: 1, available_stock: 1, reserved_stock: 0)
    start = Queue.new

    threads = Array.new(2) do
      Thread.new do
        start.pop
        e2e_post("/products/#{product.id}/reservations", quantity: 1).first
      end
    end
    2.times { start << true }

    aggregate_failures do
      expect(threads.map(&:value).sort).to eq([ 201, 409 ])
      expect(stocks).to eq("total_stock" => 1, "available_stock" => 0, "reserved_stock" => 1)
    end
  end
end
