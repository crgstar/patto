class FeedReader < Sticky
  has_many :sticky_feed_sources,
           -> { order(position: :asc) },
           foreign_key: :sticky_id,
           dependent: :destroy

  has_many :feed_sources, through: :sticky_feed_sources
  has_many :feed_items, through: :feed_sources

  after_discard :discard_sticky_feed_sources

  def unread_items_count(user)
    feed_items.left_joins(:user_feed_items)
      .where('user_feed_items.user_id IS NULL OR (user_feed_items.user_id = ? AND user_feed_items.read = ?)', user.id, false)
      .distinct
      .count
  end

  def fetch_all_feeds
    feed_sources.each(&:fetch_and_save_items)
  end

  private

  def discard_sticky_feed_sources
    sticky_feed_sources.each(&:discard)
  end
end
