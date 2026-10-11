class InventoryReservationService
  def initialize(product:)
    @product = product
  end

  def call(quantity:)
    @product.with_lock do
      current = @product.inventory_position

      updated = current.reserve(quantity)

      @product.update!(
        available_stock: updated.available_stock,
        reserved_stock: updated.reserved_stock
      )
    end
  end
end
