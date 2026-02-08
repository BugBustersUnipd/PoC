# ImageGenerationParams - Request Object per validazione input generazione immagini
#
# Questo oggetto incapsula validazione e normalizzazione parametri HTTP:
# - Converte stringhe in Integer (.to_i)
# - Applica default (width/height = 1024 se nil)
# - Valida presenza campi obbligatori (prompt, company_id)
# - Fornisce metodo to_service_params per passare a ImageService

class ImageGenerationParams
  # attr_reader = genera getter methods per leggere instance variables
  # Equivalente a scrivere:
  #   def prompt; @prompt; end
  #   def company_id; @company_id; end
  #   ...
  #
  # Perché attr_reader?
  # - @variables sono private in Ruby (non accessibili da fuori classe)
  # - attr_reader rende valori leggibili: params.prompt, params.width, etc.
  # - attr_writer genererebbe setter (params.prompt = ...), non voluto qui
  # - attr_accessor genererebbe getter + setter, ma vogliamo oggetto immutabile
  attr_reader :prompt, :company_id, :conversation_id, :width, :height, :seed, :errors

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
  # - prompt: strip whitespace, converte nil in ""
  # - company_id: converte a Integer ("123" → 123)
  # - width/height: default 1024 se nil/blank
  # - seed: nil se non fornito, Integer se presente
  #
  # @param prompt [String, nil] descrizione immagine
  # @param company_id [String, Integer, nil] ID azienda (da params[:company_id])
  # @param conversation_id [String, Integer, nil] ID conversazione (optional)
  # @param width [String, Integer, nil] larghezza pixel (default 1024)
  # @param height [String, Integer, nil] altezza pixel (default 1024)
  # @param seed [String, Integer, nil] seed riproducibilità (optional)

  def initialize(prompt:, company_id:, conversation_id: nil, width: nil, height: nil, seed: nil)
    # Normalizza prompt: strip rimuove spazi inizio/fine
    # if prompt = guard clause, evita .strip su nil (causerebbe NoMethodError)
    # .to_s converte nil in "", altri valori in String
    @prompt = prompt.to_s.strip if prompt
    
    # Converte company_id a Integer
    # .present? = true se valore non è nil/empty/blank (metodo Rails)
    # ? true_val : false_val = operatore ternario (if inline)
    # .to_i converte String → Integer ("123" → 123, "abc" → 0)
    @company_id = company_id.present? ? company_id.to_i : nil
    
    # Stesso pattern per conversation_id (optional)
    @conversation_id = conversation_id.present? ? conversation_id.to_i : nil
    
    # width con default 1024
    # .presence ritorna nil se blank, altrimenti ritorna valore
    # || 1024 = operatore OR, fornisce default se .presence ritorna nil
    # (width.presence || 1024).to_i = pattern comune Ruby per "valore o default"
    @width = (width.presence || 1024).to_i
    
    # Stesso pattern per height
    @height = (height.presence || 1024).to_i
    
    # seed optional: nil se non fornito
    @seed = seed.present? ? seed.to_i : nil
    
    # Array errori validazione (popolato da valid?)
    @errors = []
  end

  # Valida che campi obbligatori siano presenti
  #
  # Campi obbligatori:
  # - prompt: descrizione immagine (non può essere blank)
  # - company_id: ownership immagine (non può essere nil/blank)
  def valid?
    # Reset errori (necessario se valid? chiamato più volte)
    @errors = []
    
    # .blank? = true se valore è nil/empty/whitespace-only (Rails method)
    # || = OR logico, errore se uno dei due è blank
    # << = append a array
    # Modifier if = esegui solo se condizione vera
    errors << "prompt e company_id sono obbligatori" if prompt.blank? || company_id.blank?

    if BANNED_PATTERNS.any? { |pattern| prompt.match?(pattern) }
      errors << "prompt contiene istruzioni non permesse"
    end
    
    # .empty? = true se array non ha elementi
    # Validazione passa se errors array vuoto
    errors.empty?
  end

  # Converte parametri in Hash per passare a ImageService
  def to_service_params
    # Hash con Symbol keys
    # Tutti i valori sono già normalizzati dal constructor
    {
      prompt: prompt,
      company_id: company_id,
      conversation_id: conversation_id,
      width: width,
      height: height,
      seed: seed
    }
  end
end
