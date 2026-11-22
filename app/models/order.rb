# evilutionは変異を評価する前にOrderを読み込むため、親クラスを外しても既存のクラスを開き直すだけになる。
class Order < ApplicationRecord # evilution:disable
  enum :status, {
    pending: 0,
    paid: 1,
    shipped: 2,
    cancelled: 3
  }

  def cancellable?
    pending? || paid?
  end
end
