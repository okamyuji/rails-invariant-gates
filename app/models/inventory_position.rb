class InventoryPosition
  class InvalidState < StandardError; end
  class InvalidQuantity < StandardError; end
  class InsufficientStock < StandardError; end

  # evilutionは変異を既存のクラスへ重ねて読み込むため、attr_readerを消す変異は元のメソッドが残り区別できない。
  attr_reader :total_stock, # evilution:disable
              :available_stock,
              :reserved_stock

  def initialize(total_stock:, available_stock:, reserved_stock:)
    @total_stock = total_stock
    @available_stock = available_stock
    @reserved_stock = reserved_stock

    validate_invariants!

    freeze
  end

  def reserve(quantity)
    # Integerの派生クラスはインスタンスを作れないため、is_a?と書くと区別できない等価ミュータントが残る。
    unless quantity.instance_of?(Integer) && quantity.positive?
      raise InvalidQuantity
    end

    if quantity > available_stock
      raise InsufficientStock
    end

    self.class.new(
      total_stock: total_stock,
      available_stock: available_stock - quantity,
      reserved_stock: reserved_stock + quantity
    )
  end

  private

  def validate_invariants!
    stocks = [
      total_stock,
      available_stock,
      reserved_stock
    ]

    unless stocks.all? { |stock| stock.instance_of?(Integer) }
      raise InvalidState
    end

    if stocks.any?(&:negative?)
      raise InvalidState
    end

    unless available_stock + reserved_stock == total_stock
      raise InvalidState
    end
  end
end
