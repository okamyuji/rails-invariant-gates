class OrderCancellationService
  def initialize(order:)
    @order = order
  end

  def call
    return false unless @order.cancellable?

    @order.update!(status: :cancelled)
  end
end
