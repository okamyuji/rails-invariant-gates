# ApplicationController の allow_browser はブラウザ以外の要求を拒否するため、APIは別の基底クラスにする。
class ApiController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render_error("Not found", :not_found)
  end

  private

  # 基数を省くと "010" が8、"0x1A" が26になるため、10進数に限定する。
  def integer_param(key)
    Integer(params[key].to_s, 10, exception: false)
  end

  def render_error(message, status, **extra)
    render json: { error: message, **extra }, status:
  end
end
