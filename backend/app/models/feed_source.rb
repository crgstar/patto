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
end
