class StickyFeedSource < ApplicationRecord
  include Discard::Model

  belongs_to :sticky
  belongs_to :feed_source

  validates :sticky, presence: true
  validates :feed_source, presence: true
  validates :feed_source_id, uniqueness: { scope: :sticky_id }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope { kept.order(position: :asc) }
end
