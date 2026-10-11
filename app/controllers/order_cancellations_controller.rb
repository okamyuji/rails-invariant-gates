class OrderCancellationsController < ApiController
  def create
    order = Order.find(params[:order_id])

    if OrderCancellationService.new(order:).call
      render json: { status: order.status }
    else
      render_error("Order cannot be cancelled", :conflict, status: order.status)
    end
  end
end
