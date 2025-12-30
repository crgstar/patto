module Api
  class FeedSourcesController < ApplicationController
    include JsonWebToken
    before_action :authorize_request
    before_action :set_feed_source, only: [:update, :destroy, :refresh]

    def index
      feed_sources = current_user.feed_sources.order(created_at: :desc)
      render json: { feed_sources: feed_sources }, status: :ok
    end

    def create
      # 論理削除されたレコードを含めて検索
      feed_source = current_user.feed_sources.with_discarded.find_by(url: feed_source_params[:url])

      if feed_source&.discarded?
        # 論理削除されたレコードが存在する場合は復元
        feed_source.undiscard
        feed_source.update!(feed_source_params)
      else
        # 新規作成
        feed_source = current_user.feed_sources.build(feed_source_params)
        feed_source.save!
      end

      # フィード作成後、すぐにフィードデータを取得して名前を更新
      feed_source.fetch_and_save_items

      render json: { feed_source: feed_source.reload }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    def update
      @feed_source.update!(feed_source_params)
      render json: { feed_source: @feed_source }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    def destroy
      @feed_source.discard
      head :no_content
    end

    def refresh
      if @feed_source.fetch_and_save_items
        render json: { feed_source: @feed_source.reload }, status: :ok
      else
        render json: { error: "Failed to refresh feed: #{@feed_source.fetch_error}" }, status: :unprocessable_entity
      end
    end

    private

    def set_feed_source
      @feed_source = current_user.feed_sources.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Feed source not found' }, status: :not_found
    end

    def feed_source_params
      params.require(:feed_source).permit(:url, :title, :description)
    end
  end
end
