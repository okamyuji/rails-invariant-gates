class ShippingQuotesController < ApiController
  def show
    amount = integer_param(:order_amount)
    return render_error("Invalid amount", :unprocessable_content) unless amount

    render json: { shipping_fee: ShippingCalculator.new(order_amount: amount).calculate }
  rescue ArgumentError => e
    render_error(e.message, :unprocessable_content)
  end
end
