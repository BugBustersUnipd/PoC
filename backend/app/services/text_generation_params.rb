# TextGenerationParams - Request Object per validazione input generazione testo
#
# Questo oggetto incapsula validazione e normalizzazione parametri HTTP:
# - Strip whitespace da prompt e tone_name
# - Converte company_id/conversation_id a Integer
# - Valida presenza campi obbligatori:
#   * prompt e company_id: SEMPRE obbligatori
#   * tone_name: obbligatorio SOLO se conversation_id assente (nuova chat)
#   * conversation_id: opzionale (continua chat esistente)
#   * tone_name e conversation_id: MUTUAMENTE ESCLUSIVI (non puoi specificare entrambi)
# - Fornisce metodo to_service_params per passare a AiService
#
# Pattern: Request Object (Form Object)
# - Separa validazione input da business logic
# - Controller delega validazione a questo oggetto
# - Service riceve parametri già validati e normalizzati
#
# Logica tono:
# - Nuova chat (conversation_id nil): tone_name OBBLIGATORIO
# - Continua chat (conversation_id presente): tone_name VIETATO (usa quello salvato)
class TextGenerationParams
  # attr_reader genera getter methods per leggere instance variables
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
  /(sei|tu\s+sei)\s+(un|una)?\s*(ai|intelligenza\s+artificiale|assistente|modello\s+linguistico)/i,

  # Placeholder da bloccare
  /\[.*?\]/,  # Qualsiasi testo tra parentesi quadre
  /\{.*?\}/,  # Qualsiasi testo tra parentesi graffe
  /<.*?>/,   # Qualsiasi testo tra parentesi angolari
  /inserire\s+(qui|qui\s+sotto|nel\s+campo)/i,
  /specificare\s+(qui|il\s+valore|la\s+descrizione)/i,
  /compilare\s+con/i,
  /sostituire\s+con/i
]


  # Costruttore: valida e normalizza input HTTP
  #
  # Normalizzazioni applicate:
  # - prompt: strip whitespace
  # - tone_name: strip whitespace
  # - company_id: converte a Integer
  # - conversation_id: converte a Integer se presente
  #
  # @param prompt [String, nil] testo/richiesta per IA
  # @param tone_name [String, nil] nome tono comunicativo (vietato se conversation_id presente)
  # @param company_id [String, Integer, nil] ID azienda
  # @param conversation_id [String, Integer, nil] ID conversazione per context (optional)
  def initialize(prompt:, tone_name:, company_id:, conversation_id: nil)
    @prompt = prompt.to_s.strip if prompt
    @tone_name = tone_name.to_s.strip if tone_name
    @company_id = company_id.present? ? company_id.to_i : nil
    @conversation_id = conversation_id.present? ? conversation_id.to_i : nil
    @errors = []
  end

  # Valida che campi obbligatori siano presenti e regole di conflitto
  #
  # Regole:
  # 1. prompt e company_id: SEMPRE obbligatori
  # 2. tone_name e conversation_id: MUTUAMENTE ESCLUSIVI
  #    - Se conversation_id presente: tone_name DEVE essere nil/blank
  #    - Se conversation_id assente: tone_name DEVE essere presente
  #
  # @return [Boolean] true se validazione passa
  def valid?
    @errors = []
    
    # Regola 1: Campi base obbligatori
    errors << "Prompt e company_id sono obbligatori" if prompt.blank? || company_id.blank?

    # Regola 2: tone_name e conversation_id mutuamente esclusivi
    # Se conversation_id è presente, tone_name DEVE essere blank
    if conversation_id.present? && tone_name.present?
      errors << "Non puoi specificare 'tone' quando continui una conversazione esistente"
    end

    # Se conversation_id assente, tone_name DEVE essere presente
    if conversation_id.blank? && tone_name.blank?
      errors << "Tone è obbligatorio per nuove conversazioni"
    end

    # Validazione prompt sicurezza
    if BANNED_PATTERNS.any? { |pattern| prompt.match?(pattern) }
      errors << "Il prompt contiene istruzioni non permesse o placeholder non consentiti"
    end

    # Validazione passa se errors array vuoto
    errors.empty?
  end

  # Converte parametri in Hash per passare a AiService
  #
  # @return [Hash] parametri normalizzati
  def to_service_params
    {
      prompt: prompt,
      tone_name: tone_name,
      company_id: company_id,
      conversation_id: conversation_id
    }
  end
end
