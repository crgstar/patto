class FeedItem < ApplicationRecord
  include Discard::Model

  belongs_to :feed_source
  has_many :user_feed_items, dependent: :destroy

  validates :guid, presence: true, uniqueness: { scope: :feed_source_id }
  validates :title, presence: true, length: { maximum: 500 }
  validates :url, presence: true, length: { maximum: 2048 }
  validates :feed_source, presence: true

  default_scope { kept.order(published_at: :desc) }

  def read_by?(user)
    user_feed_items.find_by(user: user)&.read || false
  end

  def mark_as_read_by(user)
    user_feed_items.find_or_create_by!(user: user).tap do |ufi|
      ufi.update!(read: true, read_at: Time.current)
    end
  end

  def mark_as_unread_by(user)
    user_feed_items.find_or_create_by!(user: user).tap do |ufi|
      ufi.update!(read: false, read_at: nil)
    end
  end
end
