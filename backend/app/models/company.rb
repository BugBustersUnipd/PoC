class Company < ApplicationRecord
  has_many :tones, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :documents, dependent: :destroy

  validates :name, presence: true
end
