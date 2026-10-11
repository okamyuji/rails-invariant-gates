require "rails_helper"
require_relative "../support/e2e_server"

RSpec.describe "POST /orders/:order_id/cancellation", type: :e2e do
  # サーバーは別プロセスなので、作ったレコードをコミットして見せる。
  self.use_transactional_tests = false

  after { Order.delete_all }

  %w[pending paid].each do |status|
    it "#{status}の注文はキャンセルされ、DBもcancelledになる" do
      order = Order.create!(status:)

      response = e2e_post("/orders/#{order.id}/cancellation")

      aggregate_failures do
        expect(response).to eq([ 200, { "status" => "cancelled" } ])
        expect(order.reload).to be_cancelled
      end
    end
  end

  %w[shipped cancelled].each do |status|
    it "#{status}の注文は409を返し、状態を変えない" do
      order = Order.create!(status:)

      response = e2e_post("/orders/#{order.id}/cancellation")

      aggregate_failures do
        expect(response).to eq([ 409, { "error" => "Order cannot be cancelled", "status" => status } ])
        expect(order.reload.status).to eq(status)
      end
    end
  end

  it "存在しない注文は404を返す" do
    expect(e2e_post("/orders/0/cancellation")).to eq([ 404, { "error" => "Not found" } ])
  end
end
