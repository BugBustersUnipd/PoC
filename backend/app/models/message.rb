# Message: singolo messaggio in una conversazione (chat)
# 
# Struttura: una Conversation ha molti Message (chat log history)
# Ogni messaggio è alternato: user → assistant → user → ...
# 
# ROLE (ruolo):
#   - "user": messaggio dell'utente (input umano)
#   - "assistant": risposta dell'IA (output Bedrock)
# 
# Bedrock API Converse richiede messaggi alternati (no 2 user/assistant consecutivi)
# AiService.build_clean_messages() normalizza lo storico prima di inviare a Bedrock
#
class Message < ApplicationRecord
  # Relazione obbligatoria: ogni messaggio appartiene a UNA conversazione
  # Foreign key: conversation_id nel DB
  belongs_to :conversation

  # Costante: ruoli validi (user o assistant)
  # %w[...].freeze = array di stringhe immutabile ("user" e "assistant")
  # .freeze = rende l'array immutabile (prevent accidental modification)
  VALID_ROLES = %w[user assistant].freeze

  # Validazioni
  # presence: true = campo DEVE essere presente (non nil, non stringa vuota)
  # inclusion: { in: VALID_ROLES } = valore DEVE essere dentro la lista VALID_ROLES
  # Se salvi Message.create(role: "admin"), validation fallisce ("admin" non in lista)
  validates :role, presence: true, inclusion: { in: VALID_ROLES }
  
  # Il contenuto (testo) del messaggio DEVE essere presente
  validates :content, presence: true
end
