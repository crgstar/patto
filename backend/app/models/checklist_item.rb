class ChecklistItem < ApplicationRecord
  include Discard::Model

  belongs_to :sticky

  validates :content, presence: true
  validates :sticky, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope { kept.order(position: :asc) }

  def toggle_checked!
    update!(checked: !checked)
  end
end
