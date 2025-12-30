class FeedSource < ApplicationRecord
  include Discard::Model

  belongs_to :user
  has_many :sticky_feed_sources, dependent: :destroy
  has_many :stickies, through: :sticky_feed_sources
  has_many :feed_items, dependent: :destroy

  validates :url, presence: true, length: { maximum: 2048 }
  validates :url, format: { with: URI::regexp(%w[http https]), message: "is invalid" }
  validates :url, uniqueness: { scope: :user_id }
  validates :user, presence: true

  default_scope { kept }

  def fetch_and_save_items
    # HTTPartyでフィードを取得
    response = HTTParty.get(url)

    # HTTPステータスコードを確認
    unless response.success?
      update(last_fetched_at: Time.current, fetch_error: "Failed to fetch feed: HTTP #{response.code}")
      return false
    end

    # Feedjiraでパース
    feed = Feedjira.parse(response.body)

    # feed が nil またはパースできなかった場合
    unless feed
      update(last_fetched_at: Time.current, fetch_error: "Failed to parse feed")
      return false
    end

    # タイトル・説明が空の場合のみフィードから取得した値で上書き
    update(
      title: title.presence || feed.title,
      description: description.presence || feed.description,
      last_fetched_at: Time.current,
      fetch_error: nil
    )

    feed.entries.each do |entry|
      feed_items.find_or_create_by!(guid: entry.entry_id || entry.url) do |item|
        item.title = entry.title.presence || 'Untitled'
        item.url = entry.url
        item.description = entry.summary
        item.content = entry.content
        item.author = entry.author
        item.published_at = entry.published
      end
    end

    true
  rescue Feedjira::NoParserAvailable => e
    update(last_fetched_at: Time.current, fetch_error: "Unsupported feed format: #{e.message}")
    false
  rescue StandardError => e
    update(last_fetched_at: Time.current, fetch_error: e.message)
    false
  end

  # URLからドメインを抽出
  def domain
    return '' if url.blank?

    uri = URI.parse(url)
    hostname = uri.hostname
    return '' if hostname.blank?

    # 先頭の "www." を除去
    hostname.sub(/^www\./, '')
  rescue URI::InvalidURIError
    ''
  end
end
