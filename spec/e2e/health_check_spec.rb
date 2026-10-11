require "rails_helper"
require_relative "../support/e2e_server"

RSpec.describe "E2Eサーバー", type: :e2e do
  it "子プロセスのPumaが /up に200を返す" do
    status, = e2e_get("/up")

    expect(status).to eq(200)
  end
end
