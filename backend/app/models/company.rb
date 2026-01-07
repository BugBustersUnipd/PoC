# Company: modello per le aziende/clienti
#
# RELAZIONI (has_many, belongs_to, ecc.) = come "foreign key" ma a livello ORM:
#   - has_many :tones = "Un'azienda ha molti toni"
#   - SQL: SELECT * FROM tones WHERE company_id = ?  (quando fai company.tones)
#   - .dependent: :destroy = se cancelli l'azienda, cancella ANCHE tutti i toni associati
#     (diverso da :nullify che mette company_id = NULL, o :restrict che rifiuta cancellazione)
#
class Company < ApplicationRecord
  # Associazioni: una Company ha tanti Tone, Conversation, Document
  # :dependent: :destroy = cancellazione a cascata (cascading delete)
  # Quando cancelli una Company, Rails cancella TUTTI i suoi Tone/Conversation/Document
  has_many :tones, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :documents, dependent: :destroy

  # Validazioni: regole che il model deve rispettare prima di salvare nel DB
  # :name, presence: true = il campo 'name' DEVE essere presente (non nil, non stringa vuota)
  # Se validazione fallisce, model.save ritorna false e model.errors contiene i messaggi
  validates :name, presence: true
end
