module Api
  class ChecklistItemsController < ApplicationController
    include JsonWebToken
    before_action :authorize_request
    before_action :set_sticky
    before_action :set_checklist_item, only: [:update, :destroy]

    def create
      item = @sticky.checklist_items.build(checklist_item_params)
      item.save!
      render json: { checklist_item: item }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    def update
      @checklist_item.update!(checklist_item_params)
      render json: { checklist_item: @checklist_item }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    def destroy
      @checklist_item.discard
      head :no_content
    end

    def reorder
      checklist_items_params = params.require(:checklist_items)

      ActiveRecord::Base.transaction do
        checklist_items_params.each do |item_params|
          item = @sticky.checklist_items.find(item_params[:id])
          item.update!(position: item_params[:position])
        end
      end

      render json: { message: 'Checklist items reordered successfully' }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Checklist item not found' }, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def set_sticky
      @sticky = current_user.stickies.find(params[:sticky_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Sticky not found' }, status: :not_found
    end

    def set_checklist_item
      @checklist_item = @sticky.checklist_items.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Checklist item not found' }, status: :not_found
    end

    def checklist_item_params
      params.require(:checklist_item).permit(:content, :checked, :position)
    end
  end
end
