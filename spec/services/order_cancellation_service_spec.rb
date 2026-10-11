require "rails_helper"

RSpec.describe OrderCancellationService do
  describe "#call" do
    context "CXL-01 キャンセル可能な注文の場合" do
      it "注文ステータスをcancelledに変更する" do
        order = Order.create!(status: :pending)

        service = described_class.new(order: order)

        expect {
          service.call
        }.to change {
          order.reload.status
        }.from("pending").to("cancelled")
      end

      it "trueを返す" do
        order = Order.create!(status: :pending)

        service = described_class.new(order: order)

        expect(service.call).to be(true)
      end
    end

    context "CXL-03 ステータスの更新に失敗した場合" do
      it "失敗を握りつぶさずに例外を伝える" do
        order = Order.create!(status: :pending)
        # Orderにはバリデーションがなく、実DBのどの状態からも保存の失敗を起こせない。
        # update!をupdateに変える変異を見つけるため、ここだけvalid?をstubする。
        allow(order).to receive(:valid?).and_return(false)

        service = described_class.new(order: order)

        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "CXL-02 発送済みの注文の場合" do
      it "ステータスを変更せずfalseを返す" do
        order = Order.create!(status: :shipped)

        service = described_class.new(order: order)

        expect(service.call).to be(false)
        expect(order.reload).to be_shipped
      end
    end
  end
end
