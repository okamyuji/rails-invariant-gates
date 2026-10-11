class ProductReservationsController < ApiController
  def create
    product = Product.find(params[:product_id])
    # 整数にできない値はnilのまま渡し、InventoryPosition に InvalidQuantity として拒否させる。
    InventoryReservationService.new(product:).call(quantity: integer_param(:quantity))

    render json: product.slice(:total_stock, :available_stock, :reserved_stock), status: :created
  end
end
