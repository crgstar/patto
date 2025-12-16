class Sticky < ApplicationRecord
  include Discard::Model

  belongs_to :user
  has_many :sticky_feed_sources, dependent: :destroy
  has_many :feed_sources, through: :sticky_feed_sources

  validates :type, presence: true
  validates :user, presence: true
  validates :x, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :y, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :width, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :height, presence: true, numericality: { only_integer: true, greater_than: 0 }

  default_scope { kept.order(position: :asc) }

  # 自動配置メソッド（座標が未設定の場合にデフォルト値を設定）
  def auto_position!
    # user が nil の場合はスキップ
    return unless user

    # すべての座標がデフォルト値（x=0, y=0, width=1, height=1）の場合にのみ自動配置
    # それ以外は明示的に設定されたとみなしてスキップ
    return unless x == 0 && y == 0 && width == 1 && height == 1

    max_y = user.stickies.maximum(:y) || -1
    self.x = 0
    self.y = max_y + 1
    self.width = 1
    self.height = 1
  end

  before_validation :auto_position!, if: :new_record?
end
