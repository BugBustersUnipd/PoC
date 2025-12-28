require "aws-sdk-bedrockruntime"
require "json"

# AiService
# - Fornisce un'interfaccia semplice per generare testo con Amazon Bedrock usando l'API "Converse".
# - Gestisce lo storico conversazionale in modo sicuro (formato richiesto da Bedrock),
#   seleziona il modello (default: Amazon Nova Lite) e applica un fallback opzionale.
# - Mantiene le API e la struttura del servizio semplici per l'uso dai controller.
class AiService
  # Numero massimo di messaggi di contesto da mantenere
  MAX_CONTEXT_MESSAGES = 10

  # Carica il profilo di configurazione per la generazione testo
  BEDROCK_CONFIG = ::BEDROCK_CONFIG_GENERATION

  # Default e configurazione
  FALLBACK_MODEL_ENV = "BEDROCK_FALLBACK_MODEL_ID"
  REGION_DEFAULT     = "us-east-1"

  def initialize
    # Regione Bedrock: assicurarsi che i modelli siano abilitati nella stessa regione
    @region = BEDROCK_CONFIG["region"]
    @client = Aws::BedrockRuntime::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"],
      region: @region
    )
  end

  # Genera il testo usando Amazon Bedrock (API Converse)
  # Parametri:
  # - testo_utente: Stringa con la richiesta dell'utente
  # - company_id: ID dell'azienda (per contesto e persistenza conversazione)
  # - nome_tono: Nome del tono salvato su DB (istruzioni addizionali)
  # - conversation_id: ID conversazione esistente (opzionale) per mantenere il contesto
  # Ritorna: Hash con chiavi :text e :conversation_id
  def genera(testo_utente, company_id, nome_tono, conversation_id: nil)
    company      = Company.find(company_id)
    conversation = fetch_or_create_conversation(company, conversation_id)

    tono_db            = company.tones.find_by(name: nome_tono)
    istruzioni_tono    = tono_db&.instructions.presence || "Rispondi in modo professionale."
    descrizione_azienda = company.description.presence || ""

    system_prompt = build_system_prompt(company.name, descrizione_azienda, istruzioni_tono)

    # Preleva lo storico della conversazione
    context_messages = conversation.messages.order(:created_at).last(MAX_CONTEXT_MESSAGES)

    # Pulisce/normalizza i messaggi per la Converse API
    # Perché farlo "a mano"?
    # - Bedrock richiede un array di messaggi con role "user"/"assistant" alternati e contenuti non vuoti.
    # - Inviare due "user" consecutivi o iniziare con "assistant" può produrre errori di validazione.
    # - Unire messaggi consecutivi riduce rumore e token sprecati, migliorando costi e qualità output.
    messages = build_clean_messages(context_messages, testo_utente)

    # Selezione modello dal profilo text_generation
    model_id = BEDROCK_CONFIG["model_id"]
    Rails.logger.debug("Bedrock converse → region=#{@region} model_id=#{model_id}")

    response = invoke_bedrock_with_fallback(model_id, messages, system_prompt)

    output_text = response.output.message.content[0].text

    # Persistenza dei messaggi
    conversation.messages.create!(role: "user", content: testo_utente)
    conversation.messages.create!(role: "assistant", content: output_text)

    { text: output_text, conversation_id: conversation.id }
  end

  private

  # Invoca Bedrock e in caso di errori comuni (es. AccessDenied per modelli Marketplace
  # non abilitati o Throttling) ritenta con un eventuale modello di fallback definito via ENV.
  def invoke_bedrock_with_fallback(model_id, messages, system_prompt)
    converse_with_model(model_id, messages, system_prompt)
  rescue Aws::BedrockRuntime::Errors::AccessDeniedException, Aws::BedrockRuntime::Errors::ThrottlingException => e
    Rails.logger.warn("Bedrock error #{e.class} for model=#{model_id} in region=#{@region}: #{e.message}")
    fallback = ENV[FALLBACK_MODEL_ENV].presence
    if fallback && fallback != model_id
      Rails.logger.info("Retrying with fallback model=#{fallback}")
      converse_with_model(fallback, messages, system_prompt)
    else
      raise
    end
  end

  # Wrapper dell'API "Converse": accetta messaggi normalizzati + prompt di sistema
  # e imposta una configurazione di inferenza stabile e parsimoniosa.
  def converse_with_model(model_id, messages, system_prompt)
    @client.converse(
      model_id: model_id,
      messages: messages,
      system: [ { text: system_prompt } ],
      inference_config: bedrock_inference_config
    )
  end

  # Impostazioni di inferenza dal profilo text_generation
  # - max_tokens: limita la lunghezza dell'output (controllo costi)
  # - temperature: 0.7 per risposte più creative e naturali
  def bedrock_inference_config
    {
      max_tokens: BEDROCK_CONFIG["max_tokens"],
      temperature: BEDROCK_CONFIG["temperature"]
    }
  end

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

  # Normalizza lo storico per la Converse API:
  # - unisce messaggi consecutivi dello stesso ruolo
  # - garantisce che la conversazione inizi con "user"
  # - evita contenuti vuoti
  def build_clean_messages(context_messages, current_user_text)
    messages = []

    # PRIMO CICLO: Processa tutti i messaggi dello storico della conversazione
    context_messages.each do |msg|
      # Estrae il ruolo del messaggio e lo converte in minuscolo ("user" o "assistant")
      # Se msg.role è nil, usa una stringa vuota come default
      role    = (msg.role || "").downcase
      # Estrae il contenuto del messaggio; se vuoto, usa un punto "." come placeholder
      content = msg.content.presence || "."

      # LOGICA DI MERGE: Se l'ultimo messaggio in 'messages' ha lo stesso ruolo
      # del messaggio corrente, uniscili in un solo messaggio per evitare
      # messaggi "user" o "assistant" consecutivi che Bedrock non accetta
      if messages.any? && messages.last[:role] == role
        # Aggiungi il nuovo contenuto all'ultimo messaggio, separato da due newline
        messages.last[:content][0][:text] += "\n\n#{content}"
      else
        # Altrimenti, crea un nuovo messaggio con il formato richiesto da Bedrock
        messages << { role: role, content: [ { text: content } ] }
      end
    end

    # SECONDO CICLO: Aggiungi il testo attuale dell'utente
    # Se l'ultimo messaggio è un "user", unisci il nuovo testo al suo contenuto
    # (per evitare due "user" consecutivi)
    if messages.any? && messages.last[:role] == "user"
      messages.last[:content][0][:text] += "\n\n#{current_user_text}"
    else
      # Altrimenti, crea un nuovo messaggio "user" con il testo attuale
      messages << { role: "user", content: [ { text: current_user_text } ] }
    end

    # PULIZIA: La conversazione DEVE iniziare con un messaggio "user", non "assistant"
    # Bedrock richiede questa alternanza corretta. Rimuovi messaggi "assistant"
    # dall'inizio fino al primo "user"
    messages.shift while messages.first && messages.first[:role] == "assistant"

    # FALLBACK: Se dopo la pulizia la lista è vuota, crea un messaggio di default
    # con il testo attuale dell'utente (caso edge: storico corrotto o non valido)
    messages = [ { role: "user", content: [ { text: current_user_text } ] } ] if messages.empty?

    # Ritorna l'array di messaggi puliti e pronti per la Converse API
    messages
  end

  def fetch_or_create_conversation(company, conversation_id)
    return company.conversations.find(conversation_id) if conversation_id.present?
    company.conversations.create!
  end
end
