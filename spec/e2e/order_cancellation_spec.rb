require "rails_helper"
require_relative "../support/e2e_server"

RSpec.describe "POST /orders/:order_id/cancellation", type: :e2e do
  # サーバーは別プロセスなので、作ったレコードをコミットして見せる。
  self.use_transactional_tests = false

  # 同じテストDBを使う別のプロセスのレコードを消さないよう、この例で作ったものだけを消す。
  let(:created_orders) { [] }

  after { Order.where(id: created_orders.map(&:id)).delete_all }

  def create_order(status) = Order.create!(status:).tap { created_orders << it }

  %w[pending paid].each do |status|
    it "#{status}の注文はキャンセルされ、DBもcancelledになる" do
      order = create_order(status)

      response = e2e_post("/orders/#{order.id}/cancellation")

      aggregate_failures do
        expect(response).to eq([ 200, { "status" => "cancelled" } ])
        expect(order.reload).to be_cancelled
      end
    end
  end

  %w[shipped cancelled].each do |status|
    it "#{status}の注文は409を返し、状態を変えない" do
      order = create_order(status)

      response = e2e_post("/orders/#{order.id}/cancellation")

      aggregate_failures do
        expect(response).to eq([ 409, { "error" => "Order cannot be cancelled", "status" => status } ])
        expect(order.reload.status).to eq(status)
      end
    end
  end

  it "IDの後ろに文字が付いたURLは404を返し、その番号の注文を変えない" do
    order = create_order(:pending)

    status, = e2e_post("/orders/#{order.id}abc/cancellation")

    aggregate_failures do
      expect(status).to eq(404)
      expect(order.reload).to be_pending
    end
  end

  it "存在しない注文は404を返す" do
    expect(e2e_post("/orders/0/cancellation")).to eq([ 404, { "error" => "Not found" } ])
  end
end
