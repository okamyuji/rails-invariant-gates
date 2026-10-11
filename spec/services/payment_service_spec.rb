require "rails_helper"

RSpec.describe PaymentService do
  describe "#charge" do
    it "PAY-01 指定した金額で決済する" do
      # 外部の決済APIはテストから呼べないため、呼び出しの契約だけを代役で確かめる。
      gateway = class_double(PaymentGateway)

      allow(gateway).to receive(:charge).and_return(status: "succeeded", amount: 1000)
      stub_const("PaymentGateway", gateway)

      service = described_class.new(amount: 1000)

      expect(gateway).to receive(:charge).with(1000)

      expect(service.charge).to be(true)
    end
  end
end
