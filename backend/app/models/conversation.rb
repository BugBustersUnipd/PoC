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
# - title (string, optional): titolo conversazione per UI
# - summary (text, optional): sommario conversazione
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
  
  # has_many :messages = collezione messaggi associati
  # dependent: :destroy = elimina messaggi quando conversazione eliminata
  # Rails genera: conversation.messages, conversation.messages.create!, etc.
  has_many :messages, dependent: :destroy

  # Validazione: company deve esistere (company_id non può essere nil)
  # presence: true su belongs_to verifica che foreign key sia presente
  # Ridondante con Rails 5+ (belongs_to è required di default), ma esplicito è meglio
  validates :company, presence: true
  
  # Nota: title e summary optional, possono essere nil
  # Frontend/Service possono aggiungere titolo dopo prima risposta IA
end
