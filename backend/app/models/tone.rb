class Tone < ApplicationRecord
  belongs_to :company, optional: true

  validates :name, presence: true
  validates :instructions, presence: true
end
