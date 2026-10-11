require "rails_helper"
require_relative "../support/e2e_server"

RSpec.describe "GET /shipping_quote", type: :e2e do
  {
    "5000" => 0,
    "4999" => 500,
    "1" => 500,
    "010" => 500
  }.each do |amount, fee|
    it "注文金額#{amount}円の送料は#{fee}円になる" do
      status, body = e2e_get("/shipping_quote?order_amount=#{amount}")

      expect([ status, body ]).to eq([ 200, { "shipping_fee" => fee } ])
    end
  end

  [ "0", "-1", "abc", "3.5", "0x1A", "1_000", "+5000", "0d5000", " 5000 " ].each do |amount|
    it "注文金額#{amount.inspect}は422で拒否する" do
      status, body = e2e_get("/shipping_quote?order_amount=#{ERB::Util.url_encode(amount)}")

      expect([ status, body ]).to eq([ 422, { "error" => "Invalid amount" } ])
    end
  end

  it "注文金額がなければ422で拒否する" do
    status, body = e2e_get("/shipping_quote")

    expect([ status, body ]).to eq([ 422, { "error" => "Invalid amount" } ])
  end
end
