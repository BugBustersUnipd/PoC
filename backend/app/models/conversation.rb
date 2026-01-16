# Conversation - Model ActiveRecord per conversazioni testuali con IA
#
# Rappresenta una sessione conversazionale con storico messaggi user/assistant.
# Ogni conversazione appartiene a una Company e contiene Messages.
#
# Relazioni:
# - belongs_to :company (required) - azienda proprietaria
# - has_many :messages (dependent: :destroy) - storico messaggi
#
# Colonne database:
# - company_id (integer, foreign key, required)
# - tone_id (integer, foreign key, required) - tono comunicativo per questa conversazione
# - created_at, updated_at (timestamp, auto)
#
# Uso:
#   conv = company.conversations.create!
#   conv.messages.create!(role: "user", content: "Ciao")
#   conv.messages.create!(role: "assistant", content: "Salve")
class Conversation < ApplicationRecord
  # belongs_to = associazione many-to-one
  # Ogni conversazione ha esattamente una company
  # Rails genera metodi: conversation.company, conversation.company=, conversation.build_company
  #
  # Foreign key: company_id (integer column in conversations table)
  # Query: Conversation.find(1).company esegue SELECT * FROM companies WHERE id = ?
  belongs_to :company
  
  # belongs_to :tone (required di default in Rails 5+)
  # Ogni conversazione DEVE avere un tono comunicativo associato
  # Rails genera: conversation.tone, conversation.tone=, conversation.build_tone
  belongs_to :tone
  
  # has_many :messages = collezione messaggi associati
  # dependent: :destroy = elimina messaggi quando conversazione eliminata
  # Rails genera: conversation.messages, conversation.messages.create!, etc.
  has_many :messages, dependent: :destroy

  # Validazioni: company e tone devono esistere
  # presence: true su belongs_to verifica che foreign key sia presente
  validates :company, presence: true
  validates :tone, presence: true
end
