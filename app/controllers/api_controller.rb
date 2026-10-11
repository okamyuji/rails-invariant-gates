# ApplicationController の allow_browser はブラウザ以外の要求を拒否するため、APIは別の基底クラスにする。
class ApiController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render_error("Not found", :not_found)
  end

  rescue_from InventoryPosition::InsufficientStock do
    render_error("Insufficient stock", :conflict)
  end

  rescue_from ActionDispatch::Http::Parameters::ParseError do
    render_error("Invalid JSON", :bad_request)
  end

  rescue_from InventoryPosition::InvalidQuantity do
    render_error("Invalid quantity", :unprocessable_content)
  end

  private

  # Integer() は基数10でも "1_000"・"+5"・" 5 " を受け付けるため、符号と数字だけの文字列に限る。
  def integer_param(key)
    value = params[key].to_s
    Integer(value, 10) if value.match?(/\A-?[0-9]+\z/)
  end

  def render_error(message, status, **extra)
    render json: { error: message, **extra }, status:
  end
end
