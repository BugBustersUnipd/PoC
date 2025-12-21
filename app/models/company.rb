class Company < ApplicationRecord
  has_many :tones, dependent: :destroy
  has_many :conversations, dependent: :destroy

  validates :name, presence: true
end
