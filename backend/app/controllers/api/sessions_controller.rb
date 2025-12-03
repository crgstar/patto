module Api
  class SessionsController < ApplicationController
    include JsonWebToken

    def create
      user = User.find_by(email: params[:email]&.downcase)

      if user&.authenticate(params[:password])
        token = encode_token({ user_id: user.id })
        render json: { user: user_response(user), token: token }, status: :ok
      else
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      end
    end

    def destroy
      render json: { message: 'Logged out successfully' }, status: :ok
    end

    private

    def user_response(user)
      {
        id: user.id,
        email: user.email,
        created_at: user.created_at
      }
    end
  end
end
