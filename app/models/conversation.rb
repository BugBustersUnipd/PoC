class Conversation < ApplicationRecord
  belongs_to :company
  has_many :messages, dependent: :destroy

  validates :company, presence: true
end
