module Api
  class StickiesController < ApplicationController
    include JsonWebToken
    before_action :authorize_request
    before_action :set_sticky, only: [:update, :destroy]

    def index
      stickies = current_user.stickies
      render json: { stickies: stickies.map { |s| sticky_response(s) } }, status: :ok
    end

    def create
      sticky = current_user.stickies.build(sticky_params)

      if sticky.save
        render json: { sticky: sticky_response(sticky) }, status: :created
      else
        render json: { errors: sticky.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @sticky.update(sticky_params)
        render json: { sticky: sticky_response(@sticky) }, status: :ok
      else
        render json: { errors: @sticky.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @sticky.discard
      head :no_content
    end

    def reorder
      stickies_params = params[:stickies] || []

      stickies_params.each do |sticky_data|
        sticky = current_user.stickies.find_by(id: sticky_data[:id])
        sticky&.update(position: sticky_data[:position])
      end

      render json: { message: 'Stickies reordered successfully' }, status: :ok
    end

    private

    def set_sticky
      @sticky = current_user.stickies.find_by(id: params[:id])
      render json: { error: 'Sticky not found' }, status: :not_found unless @sticky
    end

    def sticky_params
      params.require(:sticky).permit(:type, :title, :content, :position)
    end

    def sticky_response(sticky)
      {
        id: sticky.id,
        type: sticky.type,
        title: sticky.title,
        content: sticky.content,
        position: sticky.position,
        user_id: sticky.user_id,
        created_at: sticky.created_at,
        updated_at: sticky.updated_at
      }
    end
  end
end
