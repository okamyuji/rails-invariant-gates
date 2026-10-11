# 外部決済APIのクライアントの代役。記事では呼び出し契約だけを扱う。
class PaymentGateway
  def self.charge(amount)
    { status: "succeeded", amount: amount }
  end
end
