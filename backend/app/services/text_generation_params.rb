# TextGenerationParams - Request Object per validazione input generazione testo
#
# Questo oggetto incapsula validazione e normalizzazione parametri HTTP:
# - Strip whitespace da prompt e tone_name
# - Converte company_id/conversation_id a Integer
# - Valida presenza campi obbligatori (prompt, tone_name, company_id)
# - Fornisce metodo to_service_params per passare a AiService
#
# Pattern: Request Object (Form Object)
# - Separa validazione input da business logic
# - Controller delega validazione a questo oggetto
# - Service riceve parametri già validati e normalizzati
#
# Differenza da ImageGenerationParams:
# - No width/height/seed (specifici per immagini)
# - Aggiunge tone_name (tono comunicativo per testo)
class TextGenerationParams
  # attr_reader genera getter methods per leggere instance variables
  # Vedi ImageGenerationParams per spiegazione completa attr_reader
  attr_reader :prompt, :tone_name, :company_id, :conversation_id, :errors

  BANNED_PATTERNS = [
  # Ignorare regole / istruzioni
  /ignora\s+(tutte|le|le\s+precedenti)\s+istruzioni/i,
  /non\s+seguire\s+le\s+istruzioni/i,
  /dimentica\s+le\s+regole/i,

  # Prompt / istruzioni interne
  /prompt\s+di\s+sistema/i,
  /istruzioni\s+interne/i,
  /messaggio\s+di\s+sistema/i,

  # Override del ruolo
  /agisci\s+come/i,
  /fingi\s+di\s+essere/i,
  /interpreta\s+il\s+ruolo\s+di/i,

  # Jailbreak classici
  /fai\s+qualsiasi\s+cosa/i,
  /senza\s+limitazioni/i,
  /\bDAN\b/i,

  # Identità del modello / auto-riferimento
  /(sei|tu\s+sei)\s+(un|una)?\s*(ai|intelligenza\s+artificiale|assistente|modello\s+linguistico)/i
]


  # Costruttore: valida e normalizza input HTTP
  #
  # Normalizzazioni applicate:
  # - prompt: strip whitespace
  # - tone_name: strip whitespace (es. "Formale", "Amichevole")
  # - company_id: converte a Integer
  # - conversation_id: converte a Integer se presente
  #
  # @param prompt [String, nil] testo/richiesta per IA
  # @param tone_name [String, nil] nome tono comunicativo
  # @param company_id [String, Integer, nil] ID azienda
  # @param conversation_id [String, Integer, nil] ID conversazione per context (optional)
  #
  # Esempio:
  #   params = TextGenerationParams.new(
  #     prompt: "  Scrivi email benvenuto  ",
  #     tone_name: " Formale ",
  #     company_id: "1",
  #     conversation_id: "45"
  #   )
  #   params.prompt         # => "Scrivi email benvenuto"
  #   params.tone_name      # => "Formale"
  #   params.company_id     # => 1
  #   params.conversation_id # => 45
  def initialize(prompt:, tone_name:, company_id:, conversation_id: nil)
    # Normalizza prompt: strip whitespace, converte nil in ""
    # if prompt = guard clause per evitare .strip su nil
    @prompt = prompt.to_s.strip if prompt
    
    # Normalizza tone_name: strip whitespace
    # tone_name = "Formale", "Amichevole", "Tecnico", etc.
    @tone_name = tone_name.to_s.strip if tone_name
    
    # Converte company_id a Integer
    # .present? = true se non nil/empty/blank
    # .to_i = String → Integer ("123" → 123)
    @company_id = company_id.present? ? company_id.to_i : nil
    
    # conversation_id optional per continuare conversazione esistente
    @conversation_id = conversation_id.present? ? conversation_id.to_i : nil
    
    # Array errori validazione
    @errors = []
  end

  # Valida che campi obbligatori siano presenti
  #
  # Campi obbligatori:
  # - prompt: richiesta utente (non blank)
  # - tone_name: tono comunicativo (non blank)
  # - company_id: ownership e configurazione (non nil/blank)
  #
  # @return [Boolean] true se validazione passa
  #
  # Esempio:
  #   params = TextGenerationParams.new(
  #     prompt: "",
  #     tone_name: "Formale",
  #     company_id: nil
  #   )
  #   params.valid?   # => false
  #   params.errors   # => ["prompt, tone e company_id sono obbligatori"]
  def valid?
    # Reset errori (necessario se valid? chiamato più volte)
    @errors = []
    
    # .blank? = true se nil/empty/whitespace-only
    # || = OR logico, errore se almeno uno è blank
    # << = append a array
    errors << "Prompt, tone e company_id sono obbligatori" if prompt.blank? || tone_name.blank? || company_id.blank?

    if BANNED_PATTERNS.any? { |pattern| prompt.match?(pattern) }
      errors << "Il prompt contiene istruzioni non permesse"
    end

    # Validazione passa se errors array vuoto
    errors.empty?
  end

  # Converte parametri in Hash per passare a AiService
  #
  # Service si aspetta Hash con chiavi Symbol.
  # Contract esplicito tra Request Object e Service.
  #
  # @return [Hash] parametri normalizzati:
  #   {
  #     prompt: "Scrivi email benvenuto",
  #     tone_name: "Formale",
  #     company_id: 1,
  #     conversation_id: 45
  #   }
  #
  # Uso in controller:
  #   result = ai_service.genera(**params.to_service_params)
  #   # ** = splat operator, espande Hash in named arguments
  def to_service_params
    {
      prompt: prompt,
      tone_name: tone_name,
      company_id: company_id,
      conversation_id: conversation_id
    }
  end
end
