class Order < ApplicationRecord
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
