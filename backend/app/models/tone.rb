# Tone - Model ActiveRecord per toni comunicativi
#
# Rappresenta uno stile comunicativo predefinito (Formale, Amichevole, Tecnico, etc.).
# Instructions è usato in system prompt per guidare generazione IA.
#
# Relazioni:
# - belongs_to :company (optional) - tono può essere globale (company_id = nil) o specifico azienda
#
# Colonne database:
# - name (string, required): nome tono visualizzato in UI ("Formale", "Amichevole")
# - instructions (text, required): prompt parziale per Bedrock system prompt
# - company_id (integer, foreign key, optional): nil = tono globale
# - created_at, updated_at (timestamp, auto)
#
# Uso:
#   # Tono globale (tutti possono usarlo)
#   Tone.create!(name: "Professionale", instructions: "Usa linguaggio formale...")
#
#   # Tono specifico azienda
#   company.tones.create!(name: "Brand Voice", instructions: "Rifletti valori aziendali...")
class Tone < ApplicationRecord
  # belongs_to :company con optional: true
  # optional: true = company_id può essere nil (tono globale)
  # Default Rails 5+ è required, optional: true disabilita requirement
  #
  # Toni globali vs specifici:
  # - company_id = nil: tono disponibile a tutte le aziende (es. "Formale", "Amichevole")
  # - company_id = 1: tono custom per company 1 (es. "Brand Voice Acme Corp")
  #
  # Query:
  #   Tone.where(company_id: nil)  # Tutti toni globali
  #   company.tones                # Toni specifici azienda
  belongs_to :company, optional: true
  
  # has_many :conversations = conversazioni che usano questo tono
  # dependent: :nullify = quando tono viene eliminato, imposta tone_id = nil nelle conversazioni
  # (vs destroy: eliminerebbe anche le conversazioni, che non vogliamo)
  has_many :conversations, dependent: :nullify

  # Validazioni: name e instructions obbligatori
  # presence: true = non può essere nil/empty/blank
  #
  # name: mostrato in dropdown UI ("Seleziona tono: Formale, Amichevole, ...")
  validates :name, presence: true
  
  # instructions: usato in PromptBuilder.build_system_prompt
  # Esempio: "Usa linguaggio tecnico ma accessibile. Evita gerghi. Spiega acronimi."
  validates :instructions, presence: true
  
  # Nota: nessuna validazione lunghezza, ma prompt troppo lungo può causare token overflow
  # Best practice: instructions < 200 parole
end
