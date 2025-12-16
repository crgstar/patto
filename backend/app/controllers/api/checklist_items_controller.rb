module Api
  class ChecklistItemsController < ApplicationController
    include JsonWebToken
    before_action :authorize_request
    before_action :set_sticky
    before_action :set_checklist_item, only: [:update, :destroy]

    def create
      item = @sticky.checklist_items.build(checklist_item_params)

      if item.save
        render json: { checklist_item: item }, status: :created
      else
        render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @checklist_item.update(checklist_item_params)
        render json: { checklist_item: @checklist_item }, status: :ok
      else
        render json: { errors: @checklist_item.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @checklist_item.discard
      head :no_content
    end

    def reorder
      checklist_items_params = params.require(:checklist_items)
      error_occurred = false
      error_response = nil

      ActiveRecord::Base.transaction do
        checklist_items_params.each do |item_params|
          item = @sticky.checklist_items.find_by(id: item_params[:id])

          unless item
            error_occurred = true
            error_response = { json: { error: 'Checklist item not found' }, status: :unprocessable_entity }
            raise ActiveRecord::Rollback
          end

          unless item.update(position: item_params[:position])
            error_occurred = true
            error_response = { json: { errors: item.errors.full_messages }, status: :unprocessable_entity }
            raise ActiveRecord::Rollback
          end
        end
      end

      if error_occurred
        render error_response
      else
        render json: { message: 'Checklist items reordered successfully' }, status: :ok
      end
    end

    private

    def set_sticky
      @sticky = current_user.stickies.find_by(id: params[:sticky_id])
      render json: { error: 'Sticky not found' }, status: :not_found unless @sticky
    end

    def set_checklist_item
      @checklist_item = @sticky.checklist_items.find_by(id: params[:id])
      render json: { error: 'Checklist item not found' }, status: :not_found unless @checklist_item
    end

    def checklist_item_params
      params.require(:checklist_item).permit(:content, :checked, :position)
    end
  end
end
