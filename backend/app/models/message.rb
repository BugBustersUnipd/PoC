# Message - Model ActiveRecord per messaggi singoli in conversazione
#
# Ogni messaggio ha un role ("user" o "assistant") e content (testo).
# Messages appartengono a Conversation, ordinati per created_at.
#
# Relazioni:
# - belongs_to :conversation (required)
#
# Colonne database:
# - conversation_id (integer, foreign key, required)
# - role (string, required): "user" o "assistant"
# - content (text, required): testo messaggio
# - created_at, updated_at (timestamp, auto)
#
# Validazioni:
# - role: deve essere "user" o "assistant" (inclusion validation)
# - content: non può essere blank
#
# Pattern: Value Object-like
# - Immutabile dopo creazione (nessun update previsto)
# - Parte di aggregate Conversation
class Message < ApplicationRecord
  # belongs_to :conversation = associazione many-to-one
  # Ogni messaggio appartiene a esattamente una conversazione
  belongs_to :conversation

  # Costante Array di ruoli validi
  # %w[...] = syntax Ruby per array di stringhe (equivalente ["user", "assistant"])
  # .freeze = rende array immutabile (nessuna modifica runtime)
  #
  # Perché costante?
  # - Evita typo ("users" invece "user")
  # - Riusabile in validazioni e query
  # - Documentazione chiara dei valori permessi
  VALID_ROLES = %w[user assistant].freeze

  # Validazione role: presenza + valore valido
  # presence: true = non può essere nil/empty
  # inclusion: {in: ARRAY} = valore deve essere nell'array
  #
  # Esempio errori:
  #   Message.new(role: nil)        # => "Role can't be blank"
  #   Message.new(role: "system")   # => "Role is not included in the list"
  #   Message.new(role: "user")     # => OK
  validates :role, presence: true, inclusion: { in: VALID_ROLES }
  
  # Validazione content: deve avere testo
  # presence: true verifica che content non sia nil/empty/blank
  validates :content, presence: true
  
  # Nota: nessuna validazione su lunghezza content
  # Bedrock ha limite ~100k token, ma è gestito in ConversationManager (prende ultimi 10 msg)
end
