require "aws-sdk-bedrockruntime"
require "json"

# AiService: servizio per generare testo con Amazon Bedrock IA
# 
# - Fornisce un'interfaccia semplice per generare testo usando l'API "Converse" di Bedrock.
# - Gestisce lo storico conversazionale in modo sicuro (rispetta i vincoli Bedrock):
#   * Messaggi alternati user/assistant (no 2 consecutivi dello stesso tipo)
#   * Contenuti non vuoti (placeholder "." se necessario)
# - Seleziona il modello (default: Amazon Nova Lite) e applica fallback se modello non disponibile
# - Mantiene l'API semplice per l'uso da controller
#
# FLOW TIPICO:
#   1. Controller.create(prompt, company_id, tone, conversation_id)
#   2. AiService.genera() carica dati azienda, tono, storico conversazione
#   3. build_clean_messages() normalizza storico per Bedrock (evita errori)
#   4. invoke_bedrock_with_fallback() invia a Bedrock + retry se fallisce
#   5. Salva user message + assistant response nel DB
#   6. Ritorna testo generato + conversation_id al controller
class AiService
  # CONTEXT_WINDOW: numero massimo di messaggi passati da mantenere in storico
  # Più messaggi = più context (miglior qualità risposta) ma più token spesi
  # 10 messaggi = ~5 scambi user/assistant (ragionevole compromesso)
  MAX_CONTEXT_MESSAGES = 10

  # Carica il profilo di configurazione dalla costante globale (bedrock.yml via initializer)
  # Include: region, model_id, max_tokens, temperature
  BEDROCK_CONFIG = ::BEDROCK_CONFIG_GENERATION

  # Configurazioni fallback
  # Se il modello principale non disponibile (AccessDenied), ritenta con questo
  FALLBACK_MODEL_ENV = "BEDROCK_FALLBACK_MODEL_ID"
  REGION_DEFAULT     = "us-east-1"

  def initialize
    # Inizializza il client AWS Bedrock RuntimeClient
    # Regione Bedrock: assicurarsi che i modelli siano abilitati nella stessa regione
    @region = BEDROCK_CONFIG["region"]
    
    # Crea client AWS con credenziali da ENV
    # In prod: usa AWS IAM role (env vars non servono, usa ruolo EC2/Lambda)
    # In dev: usa credenziali esplicite (AWS_ACCESS_KEY_ID, ecc. da .env)
    @client = Aws::BedrockRuntime::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"],
      region: @region
    )
  end

  # Genera il testo usando Amazon Bedrock (API Converse)
  #
  # Parametri:
  # - testo_utente (String, required): richiesta dell'utente
  # - company_id (Integer, required): ID azienda (per contesto, company.tones, etc.)
  # - nome_tono (String, required): nome del tono da applicare (es: "formale", "casual")
  # - conversation_id: (Integer, optional) ID conversazione esistente per mantenere contesto
  #     Se omesso: crea NUOVA conversazione
  #     Se fornito: usa storico messaggi precedenti (up to MAX_CONTEXT_MESSAGES)
  #
  # Ritorna:
  #   { text: "risposta generata...", conversation_id: 123 }
  #
  # Solleva:
  #   - ActiveRecord::RecordNotFound se company_id/conversation_id non esiste
  #   - Aws::BedrockRuntime::Errors::* se errore API Bedrock
  def genera(testo_utente, company_id, nome_tono, conversation_id: nil)
    # Carica company (solleva RecordNotFound se non esiste)
    company      = Company.find(company_id)
    
    # Carica conversazione esistente o ne crea una nuova
    conversation = fetch_or_create_conversation(company, conversation_id)

    # Carica tono per questa azienda (find_by ritorna nil se non trovato)
    # &. = safe navigation operator: chiama .instructions SOLO se tono_db non è nil
    # .presence = ritorna nil se stringa vuota, altrimenti la stringa
    # || = fallback: se tono_db è nil o istruzioni vuote, usa default
    tono_db            = company.tones.find_by(name: nome_tono)
    istruzioni_tono    = tono_db&.instructions.presence || "Rispondi in modo professionale."
    descrizione_azienda = company.description.presence || ""

    # Costruisce system prompt con contesto azienda + tono
    system_prompt = build_system_prompt(company.name, descrizione_azienda, istruzioni_tono)

    # Carica storico conversazione (ultimi N messaggi, ordinati cronologicamente)
    # .order(:created_at) = ordina da vecchio a nuovo (importante per flow!)
    # .last(N) = prendi ultimi N elementi (equivalente a LIMIT N, ORDER BY DESC, reverse)
    context_messages = conversation.messages.order(:created_at).last(MAX_CONTEXT_MESSAGES)

    # Normalizza messaggi per Bedrock API
    # Perché farlo? Bedrock richiede:
    #   - Role alternati: "user" → "assistant" → "user" → ...
    #   - Nessun contenuto vuoto (placeholder "." se necessario)
    #   - Iniziare sempre con "user"
    # build_clean_messages() gestisce automaticamente tutti questi vincoli
    messages = build_clean_messages(context_messages, testo_utente)

    # Seleziona modello da configurazione
    # Es: "amazon.nova-lite-v1:0" o "amazon.nova-pro-v1:0"
    model_id = BEDROCK_CONFIG["model_id"]
    Rails.logger.debug("Bedrock converse → region=#{@region} model_id=#{model_id}")

    # Invoca Bedrock con fallback se errore
    response = invoke_bedrock_with_fallback(model_id, messages, system_prompt)

    # Estrae testo dalla risposta
    # response.output.message.content = array di content blocks (testo, immagini, ecc.)
    # [0].text = primo blocco, accesso al testo
    output_text = response.output.message.content[0].text

    # Salva i messaggi nel DB (storico conversazione)
    # .create! = crea nuovo record, solleva eccezione se fallisce
    conversation.messages.create!(role: "user", content: testo_utente)
    conversation.messages.create!(role: "assistant", content: output_text)

    # Ritorna risultato con conversation_id per reuse futuri
    { text: output_text, conversation_id: conversation.id }
  end

  private

  # Invoca Bedrock e riprova con fallback se errori comuni (AccessDenied, Throttling)
  # 
  # Errori retry-abili:
  #   - AccessDeniedException: modello non abilitato nella regione (Marketplace models)
  #   - ThrottlingException: rate limit (API troppo carica temporaneamente)
  #
  # Errori non retry-abili: ValidationException, altri ServiceErrors → raise subito
  def invoke_bedrock_with_fallback(model_id, messages, system_prompt)
    converse_with_model(model_id, messages, system_prompt)
  rescue Aws::BedrockRuntime::Errors::AccessDeniedException, Aws::BedrockRuntime::Errors::ThrottlingException => e
    Rails.logger.warn("Bedrock error #{e.class} for model=#{model_id} in region=#{@region}: #{e.message}")
    
    # Legge fallback model da ENV (es: BEDROCK_FALLBACK_MODEL_ID=amazon.nova-pro-v1:0)
    # .presence = ritorna nil se stringa vuota
    fallback = ENV[FALLBACK_MODEL_ENV].presence
    
    # Se fallback definito E diverso dal modello principale
    if fallback && fallback != model_id
      Rails.logger.info("Retrying with fallback model=#{fallback}")
      # Ritenta con modello alternativo
      converse_with_model(fallback, messages, system_prompt)
    else
      # Nessun fallback, ri-solleva errore originale
      raise
    end
  end

  # Wrapper dell'API "Converse": invoca Bedrock con messaggi normalizzati + system prompt
  # 
  # Converse API è la scelta migliore per chat multi-turn perché:
  #   - Gestisce automaticamente storico messaggi (non serve context window manuale)
  #   - Alternanza role automatica (user/assistant/user...)
  #   - Supporta system prompt (prompt di sistema per ruolo/personalità)
  #   - Alternative: invoke_model (too low level), messageInvoker (deprecated)
  def converse_with_model(model_id, messages, system_prompt)
    @client.converse(
      model_id: model_id,
      messages: messages,  # Array: [{ role: "user", content: [...] }, ...]
      system: [ { text: system_prompt } ],  # System prompt (istruzioni IA)
      inference_config: bedrock_inference_config  # Temperature, max_tokens
    )
  end

  # Impostazioni di inferenza (generazione) dal profilo configuration
  # 
  # max_tokens: limite lunghezza risposta (riduce costi per token spensi)
  # temperature: 0.7 = bilanciamento tra determinismo (0) e creatività (1)
  #   - 0 = risposte sempre uguali, boring ma deterministiche
  #   - 0.7 = naturale, creativo, ma coerente
  #   - 1.0 = molto casuale, potrebbe non "raccontare senso"
  def bedrock_inference_config
    {
      max_tokens: BEDROCK_CONFIG["max_tokens"],  # Es: 500, 1000
      temperature: BEDROCK_CONFIG["temperature"]  # Es: 0.7
    }
  end

  # Costruisce il system prompt (istruzioni per l'IA)
  # 
  # Format: <<~PROMPT / PROMPT = heredoc multiriga (mantenere indentazione, strippare)
  # Includere:
  #   - RUOLO: chi è l'IA (rappresentante azienda)
  #   - CONTESTO: descrizione azienda (per personalità)
  #   - TONO: stile di comunicazione (formale, casual, ecc.)
  #   - REGOLE: istruzioni esplicite (es: "senza placeholder")
  def build_system_prompt(nome_azienda, descrizione, istruzioni_tono)
    <<~PROMPT.strip
      RUOLO: Sei l'IA ufficiale di "#{nome_azienda}".
      CONTESTO: #{descrizione}
      TONO: #{istruzioni_tono}

      REGOLE:
      - Genera solo il testo richiesto, pronto per l'invio, senza aggiungere frasi prima o dopo, ad esempio: "Certamente!" oppure "se hai bisogno di altro, fammi sapere.".
      - Non usare prefissi come "Assistant:" o simili.
      - Parla come mittente del messaggio senza presentazioni.
      - Non usare MAI placeholder tra parentesi quadre, il messaggio deve essere pronto per l'invio senza modifiche aggiuntive.
    PROMPT
  end

  # Normalizza lo storico messaggi per Bedrock Converse API
  # 
  # PROBLEMI DA RISOLVERE:
  #   1. Due "user" consecutivi → Bedrock rifiuta (formato errato)
  #   2. Due "assistant" consecutivi → Bedrock rifiuta
  #   3. Iniziare con "assistant" → Bedrock potrebbe rifiutare
  #   4. Messaggi vuoti (content = "") → wasta token e confonde l'IA
  #   5. Storico corrotto o nil → fallback a messaggio singolo
  #
  # SOLUZIONE: merge messaggi consecutivi dello stesso ruolo
  # Es: user1, user2 (stesso ruolo) → unisci con separator "\n\n"
  def build_clean_messages(context_messages, current_user_text)
    messages = []

    # FASE 1: Processa tutti i messaggi dello storico della conversazione
    context_messages.each do |msg|
      # Estrae ruolo e lo normalizza (downcase)
      # Se msg.role è nil (data corrupt), usa "" come fallback
      role    = (msg.role || "").downcase
      
      # Estrae contenuto, usa placeholder "." se vuoto
      # .presence = ritorna nil se stringa vuota/nil
      content = msg.content.presence || "."

      # LOGICA MERGE: Se ultimo messaggio ha STESSO ruolo
      # unisci il contenuto (evita "user" or "assistant" consecutivi)
      if messages.any? && messages.last[:role] == role
        # Aggiungi contenuto all'ultimo messaggio, separato da doppio newline
        # Format Bedrock: { role: "user", content: [{ text: "..." }] }
        messages.last[:content][0][:text] += "\n\n#{content}"
      else
        # Nuovo ruolo: crea nuovo messaggio nel formato richiesto da Bedrock
        messages << { role: role, content: [ { text: content } ] }
      end
    end

    # FASE 2: Aggiungi il testo attuale dell'utente
    # Se ultimo messaggio è "user", unisci il nuovo testo
    # (evita due "user" consecutivi dopo il merge della fase 1)
    if messages.any? && messages.last[:role] == "user"
      messages.last[:content][0][:text] += "\n\n#{current_user_text}"
    else
      # Altrimenti crea nuovo messaggio "user"
      messages << { role: "user", content: [ { text: current_user_text } ] }
    end

    # FASE 3: Pulizia - Bedrock richiede che INIZI con "user"
    # Rimuovi messaggi "assistant" dall'inizio finché non trovi un "user"
    # messages.shift = rimuove e ritorna primo elemento
    # while = ripeti finché condizione è vera
    messages.shift while messages.first && messages.first[:role] == "assistant"

    # FALLBACK: Se dopo la pulizia la lista è vuota (edge case: storico corrotto)
    # crea un messaggio singolo con il testo attuale
    messages = [ { role: "user", content: [ { text: current_user_text } ] } ] if messages.empty?

    # Ritorna array di messaggi puliti e pronti per Bedrock
    messages
  end

  # Carica conversazione esistente oppure ne crea una nuova
  # 
  # Se conversation_id fornito: carica quella (riusa storico messaggi)
  # Se conversation_id nil: crea conversazione nuova per questa azienda
  def fetch_or_create_conversation(company, conversation_id)
    return company.conversations.find(conversation_id) if conversation_id.present?
    company.conversations.create!
  end
end
