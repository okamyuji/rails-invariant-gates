# evilutionは変異を評価する前にProductを読み込むため、親クラスを外しても既存のクラスを開き直すだけになる。
class Product < ApplicationRecord # evilution:disable
  validates :total_stock,
            :available_stock,
            :reserved_stock,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  validate :stock_conservation

  def inventory_position
    InventoryPosition.new(
      total_stock: total_stock,
      available_stock: available_stock,
      reserved_stock: reserved_stock
    )
  end

  private

  def stock_conservation
    stocks = [
      total_stock,
      available_stock,
      reserved_stock
    ]

    # integer列は代入時に整数かnilへ型変換されるため、欠損だけを除けばよい。
    return unless stocks.all?

    unless available_stock + reserved_stock == total_stock
      errors.add(:base, "Stock conservation violated")
    end
  end
end
