# Immagini generate con Amazon Bedrock, salvate con ActiveStorage
# Appartengono a una company, opzionalmente associate a conversazione testuale
class GeneratedImage < ApplicationRecord
  belongs_to :company
  belongs_to :conversation, optional: true
  has_one_attached :image

  validates :prompt, presence: true
  validates :width, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :height, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :model_id, presence: true
end

