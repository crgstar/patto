class User < ApplicationRecord
  include Discard::Model

  has_secure_password
  has_many :stickies

  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }

  default_scope { kept }
end
