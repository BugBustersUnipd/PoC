# Tone: profilo di "stile di comunicazione" (tono/voce) per un'azienda
#
# Concetto: ogni azienda ha toni diversi (formale, amichevole, tecnico, creativo, ecc.)
# Quando generi testo con AiService, il tono viene aggiunto nel system prompt
# Esempio flow:
#   1. GeneratorController.create(prompt: "Ciao", tone: "formale", company_id: 1)
#   2. AiService.genera() cerca company.tones.find_by(name: "formale")
#   3. Aggiunge instructions nel system prompt di Bedrock
#   4. Bedrock usa il tono per generare risposta (stile formalità, vocabolario, ecc.)
#
# ESEMPIO database:
#   id | company_id | name      | instructions
#   1  | 1          | "formale" | "Rispondi sempre in modo formale, professionale, usa titoli."
#   2  | 1          | "casual"  | "Rispondi in modo friendly, colloquiale, usa emoji se appropriato."
#
class Tone < ApplicationRecord
  # Relazione opzionale: un Tone PUÒ essere non associato a nessuna azienda
  # optional: true = company_id PUÒ essere NULL
  # Caso d'uso: toni "globali" riutilizzabili, o toni in fase di setup
  # Nota: nella pratica, ogni Tone DOVREBBE avere una company (ma non forzato da DB)
  belongs_to :company, optional: true

  # Validazioni
  # :name = identificativo del tono (es: "formale", "casual", "tecnico")
  validates :name, presence: true
  
  # :instructions = istruzioni per Bedrock su come generare nel tono
  # Esempio: "Rispondi sempre in modo formale, senza contrazioni, usa 'Lei' non 'tu'."
  validates :instructions, presence: true
end
