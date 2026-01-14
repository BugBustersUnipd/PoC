# Company - Model ActiveRecord per aziende/clienti
#
# Tabella centrale per multi-tenancy: ogni risorsa appartiene a una company.
# Company ha toni comunicativi, conversazioni, documenti.
#
# Relazioni:
# - has_many :tones - toni comunicativi configurati (Formale, Amichevole, etc.)
# - has_many :conversations - storico conversazioni testuali
# - has_many :documents - documenti analizzati con Bedrock
#
# Colonne database:
# - name (string, required): nome azienda
# - description (text, optional): descrizione/contesto per system prompt
# - created_at, updated_at (timestamp, auto)
#
# Pattern: Aggregate Root (DDD)
# - Company è radice dell'aggregato, possiede toni/conversazioni/documenti
# - Eliminazione company cascades a tutte risorse dipendenti
class Company < ApplicationRecord
  # has_many = associazione one-to-many
  # dependent: :destroy = quando company eliminata, elimina anche tones associati
  #
  # Opzioni dependent:
  # - :destroy = chiama destroy su ogni record (triggera callbacks)
  # - :delete_all = DELETE SQL diretta (più veloce, no callbacks)
  # - :nullify = imposta foreign key a NULL (lascia record orfani)
  # - :restrict_with_error = impedisce eliminazione se ha dipendenze
  #
  # Scelta :destroy = vogliamo callbacks eseguiti (es. elimina file ActiveStorage)
  has_many :tones, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :documents, dependent: :destroy
  # has_many :generated_images è implicito via conversations.generated_images

  # validates = regole validazione ActiveRecord
  # presence: true = campo non può essere nil/empty/blank
  # Eseguito prima di save/create, se fallisce record.errors popolato
  #
  # Esempio:
  #   company = Company.new(name: "")
  #   company.valid?  # => false
  #   company.errors.full_messages  # => ["Name can't be blank"]
  validates :name, presence: true
  
  # Nota: description non ha validates, è optional
  # Se nil/blank, system prompt userà default generico
end
