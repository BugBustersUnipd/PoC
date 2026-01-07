# Conversation: una conversazione (chat) con messaggi user/assistant
#
# RELAZIONI:
#   - belongs_to :company = "Una conversazione appartiene a UN'azienda"
#     Rails aggiunge company_id come foreign key automaticamente
#     Chiama company.conversations.create(title: "...") per creare una nuova conversa per quell'azienda
#   - has_many :messages = "Una conversazione ha molti messaggi"
#     Quando accedi conversation.messages, Rails fa un JOIN sulla tabella messages
#
class Conversation < ApplicationRecord
  # Relazione obbligatoria: ogni conversazione DEVE appartenere a un'azienda
  # Ha un company_id non nullable nel DB
  # Accesso: conversation.company → carica la Company associata
  belongs_to :company
  
  # Relazione uno-a-molti: una conversazione contiene molti messaggi
  # :dependent: :destroy = se cancelli la conversazione, cancella tutti i suoi messaggi
  has_many :messages, dependent: :destroy

  # Validazione: presence: true per associazione (company deve essere assegnato)
  # Rails valida che company non sia nil prima di salvare
  # conversation.save solleva errore se company_id è nil
  validates :company, presence: true
end
