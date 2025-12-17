module Api
  class StickyFeedSourcesController < ApplicationController
    include JsonWebToken
    before_action :authorize_request
    before_action :set_sticky
    before_action :set_sticky_feed_source, only: [:destroy]

    def index
      sticky_feed_sources = @sticky.sticky_feed_sources.includes(:feed_source)
      render json: { sticky_feed_sources: sticky_feed_sources_response(sticky_feed_sources) }, status: :ok
    end

    def create
      # ユーザーが所有するフィードソースのみ追加可能
      feed_source = current_user.feed_sources.find(params[:sticky_feed_source][:feed_source_id])

      sticky_feed_source = @sticky.sticky_feed_sources.build(sticky_feed_source_params)
      sticky_feed_source.feed_source = feed_source
      sticky_feed_source.save!

      render json: { sticky_feed_source: sticky_feed_source }, status: :created
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Feed source not found' }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    def destroy
      @sticky_feed_source.discard
      head :no_content
    end

    def reorder
      sticky_feed_sources_params = params.require(:sticky_feed_sources)

      ActiveRecord::Base.transaction do
        sticky_feed_sources_params.each do |item_params|
          sticky_feed_source = @sticky.sticky_feed_sources.find(item_params[:id])
          sticky_feed_source.update!(position: item_params[:position])
        end
      end

      render json: { message: 'Sticky feed sources reordered successfully' }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Sticky feed source not found' }, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def set_sticky
      @sticky = current_user.stickies.find(params[:sticky_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Sticky not found' }, status: :not_found
    end

    def set_sticky_feed_source
      @sticky_feed_source = @sticky.sticky_feed_sources.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Sticky feed source not found' }, status: :not_found
    end

    def sticky_feed_source_params
      params.require(:sticky_feed_source).permit(:feed_source_id, :position)
    end

    def sticky_feed_sources_response(sticky_feed_sources)
      sticky_feed_sources.map do |sfs|
        {
          id: sfs.id,
          feed_source_id: sfs.feed_source_id,
          position: sfs.position,
          feed_source: {
            id: sfs.feed_source.id,
            url: sfs.feed_source.url,
            title: sfs.feed_source.title,
            last_fetched_at: sfs.feed_source.last_fetched_at,
            fetch_error: sfs.feed_source.fetch_error
          }
        }
      end
    end
  end
end
