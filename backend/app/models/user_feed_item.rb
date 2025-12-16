class UserFeedItem < ApplicationRecord
  include Discard::Model

  belongs_to :user
  belongs_to :feed_item

  validates :user, presence: true
  validates :feed_item, presence: true
  validates :feed_item_id, uniqueness: { scope: :user_id }

  default_scope { kept }

  scope :read_items, -> { where(read: true) }
  scope :unread_items, -> { where(read: false) }
  scope :starred_items, -> { where(starred: true) }
end
