module Api
  class FeedItemsController < ApplicationController
    include JsonWebToken
    before_action :authorize_request
    before_action :set_feed_reader
    before_action :set_feed_item, only: [:mark_as_read, :mark_as_unread]

    def index
      # FeedReaderに紐づくすべてのfeed_itemsのIDを取得
      feed_item_ids = @feed_reader.feed_items.pluck(:id)

      # feed_item_idsから実際のFeedItemを取得
      feed_items = FeedItem.where(id: feed_item_ids).includes(:user_feed_items, :feed_source)

      # フィルタリング: feed_source_id
      if params[:feed_source_id].present?
        feed_items = feed_items.where(feed_source_id: params[:feed_source_id])
      end

      # フィルタリング: read / unread
      if params[:filter] == 'read'
        feed_items = feed_items.joins(:user_feed_items)
          .where(user_feed_items: { user_id: current_user.id, read: true })
      elsif params[:filter] == 'unread'
        feed_items = feed_items.left_joins(:user_feed_items)
          .where('user_feed_items.user_id IS NULL OR (user_feed_items.user_id = ? AND user_feed_items.read = ?)', current_user.id, false)
      end

      # ソート（published_at降順）
      feed_items = feed_items.order(published_at: :desc)

      # ページネーションパラメータ
      offset = (params[:offset] || 0).to_i
      limit = (params[:limit] || 20).to_i
      limit = [limit, 100].min # 最大100件まで

      # 総件数を取得（has_more判定用）
      total_count = feed_items.count

      # ページネーション適用
      paginated_items = feed_items.offset(offset).limit(limit)

      # has_moreフラグの計算
      has_more = (offset + limit) < total_count

      # レスポンス生成（既読状態を含める）
      items_with_read_status = paginated_items.map do |item|
        item.as_json(include: { feed_source: { only: [:id], methods: [:domain] } })
            .merge(read: item.read_by?(current_user))
      end

      render json: { feed_items: items_with_read_status, has_more: has_more }, status: :ok
    end

    def mark_as_read
      @feed_item.mark_as_read_by(current_user)
      render json: { feed_item: @feed_item.as_json.merge(read: true) }, status: :ok
    end

    def mark_as_unread
      @feed_item.mark_as_unread_by(current_user)
      render json: { feed_item: @feed_item.as_json.merge(read: false) }, status: :ok
    end

    def mark_all_as_read
      @feed_reader.feed_items.each do |item|
        item.mark_as_read_by(current_user)
      end

      render json: { message: 'すべての記事を既読にしました' }, status: :ok
    end

    def refresh_all
      @feed_reader.fetch_all_feeds
      render json: { message: 'フィードを更新しました' }, status: :ok
    end

    private

    def set_feed_reader
      @feed_reader = current_user.stickies.find(params[:sticky_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Feed reader not found' }, status: :not_found
    end

    def set_feed_item
      @feed_item = @feed_reader.feed_items.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Feed item not found' }, status: :not_found
    end
  end
end
