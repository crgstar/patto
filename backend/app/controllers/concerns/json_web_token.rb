module JsonWebToken
  extend ActiveSupport::Concern

  SECRET_KEY = Rails.application.credentials.secret_key_base || ENV['SECRET_KEY_BASE']

  def encode_token(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def decode_token
    header = request.headers['Authorization']
    return nil unless header

    token = header.split(' ').last
    begin
      JWT.decode(token, SECRET_KEY)[0]
    rescue JWT::DecodeError
      nil
    end
  end

  def current_user
    return @current_user if @current_user

    decoded = decode_token
    @current_user = User.find(decoded['user_id']) if decoded
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def authorize_request
    unless current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
