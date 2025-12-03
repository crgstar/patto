module Api
  class CurrentUserController < ApplicationController
    include JsonWebToken
    before_action :authorize_request

    def show
      render json: { user: user_response(current_user) }, status: :ok
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
