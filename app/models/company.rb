class Company < ApplicationRecord
  has_many :tones, dependent: :destroy

  validates :name, presence: true
end
