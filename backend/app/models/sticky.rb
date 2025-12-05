class Sticky < ApplicationRecord
  include Discard::Model

  belongs_to :user

  validates :type, presence: true
  validates :user, presence: true

  default_scope { kept.order(position: :asc) }
end
