class Message < ApplicationRecord
  belongs_to :conversation

  VALID_ROLES = %w[user assistant].freeze

  validates :role, presence: true, inclusion: { in: VALID_ROLES }
  validates :content, presence: true
end
