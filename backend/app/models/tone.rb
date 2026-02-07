# Toni comunicativi predefiniti (Formale, Amichevole, Tecnico, etc.)
# Usati per guidare lo stile di generazione del testo tramite instructions nel system prompt
class Tone < ApplicationRecord
  belongs_to :company, optional: true
  has_many :conversations, dependent: :nullify

  validates :name, presence: true
  validates :instructions, presence: true
end
