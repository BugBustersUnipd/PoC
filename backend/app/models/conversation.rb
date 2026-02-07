# Sessioni conversazionali con storico messaggi user/assistant
# Ogni conversazione appartiene a una company e usa un tono comunicativo specifico
class Conversation < ApplicationRecord
  belongs_to :company
  belongs_to :tone
  has_many :messages, dependent: :destroy

  validates :company, presence: true
  validates :tone, presence: true
end
