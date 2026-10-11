class ShippingCalculator
  FREE_SHIPPING_THRESHOLD = 5_000
  SHIPPING_FEE = 500

  def initialize(order_amount:)
    @order_amount = order_amount
  end

  def calculate
    raise ArgumentError, "Invalid amount" if @order_amount <= 0

    return 0 if @order_amount >= FREE_SHIPPING_THRESHOLD

    SHIPPING_FEE
  end
end
