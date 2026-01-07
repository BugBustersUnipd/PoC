class GeneratorController < ActionController::API
  # Controller per generare testo/immagini tramite i servizi interni (AiService, ImageService)

  # POST /genera
  # Riceve: prompt (string), tone (nome tono), company_id (id azienda), conversation_id (opzionale)
  # Risponde con il risultato del servizio AI o con errori strutturati
  def create
    # Parametri principali
    prompt     = params[:prompt]
    tone_name  = params[:tone]
    company_id = params[:company_id]
    conversation_id = params[:conversation_id]

    # Validazione minima: prompt, tone e company sono obbligatori
    if prompt.blank? || tone_name.blank? || company_id.blank?
      return render json: { error: "prompt, tone e company_id sono obbligatori" }, status: :unprocessable_entity
    end

    # Delega la generazione a AiService (solleva RecordNotFound se riferimenti invalidi)
    result = AiService.new.genera(prompt, company_id, tone_name, conversation_id: conversation_id)
    render json: result, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    # Gestione esplicita per risorse non trovate (azienda/tono/conversazione)
    Rails.logger.error "Record non trovato: #{e.message}"
    render json: { error: "Azienda, tono o conversazione non trovati" }, status: :not_found
  rescue => e
    # Log dettagliato per debug, ma rispondi con errore generico al client
    Rails.logger.error "Errore interno: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Errore interno: #{e.message}" }, status: :internal_server_error
  end

  # GET /toni?company_id=:id
  # Lista i toni (stili di comunicazione) associati a un'azienda
  def index
    company_id = params[:company_id]
    # .blank? = controlla se nil o stringa vuota (metodo Rails specifico)
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    # find_by(id: X) = SELECT * WHERE id = X LIMIT 1, ritorna nil se non trova (diverso da find che solleva errore)
    company = Company.find_by(id: company_id)
    return render json: { error: "Azienda non trovata" }, status: :not_found unless company

    # .select(:id, :name, :instructions) = SELECT id, name, instructions FROM ... (ottimizzazione: carica solo questi campi)
    tones = company.tones.select(:id, :name, :instructions)
    # render json: crea automaticamente JSON dalla hash (ActionController::API rende ciò automatico)
    render json: {
      company: { id: company.id, name: company.name },
      tones: tones
    }, status: :ok
  end

  # GET /conversazioni?company_id=:id
  # Lista tutte le conversazioni di un'azienda (ultimi 50), ordinate per data più recente
  def conversations
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    # .where(condition) = WHERE condition, encadenabili (chainable) per query fluenti
    # .order(updated_at: :desc) = ORDER BY updated_at DESC (più recenti prima)
    # .limit(50) = LIMIT 50 (non scaricare migliaia di record)
    conversations = Conversation.where(company_id: company_id).order(updated_at: :desc).limit(50)
    # .as_json(only: [...]) = Converte a hash JSON, includendo SOLO i campi specificati (riduce peso risposta)
    render json: conversations.as_json(only: [ :id, :title, :created_at, :updated_at, :summary ])
  end

  # GET /conversazioni/:id
  # Recupera una conversazione specifica con tutti i messaggi associati
  def show_conversation
    # .includes(:messages) = EAGER LOAD i messaggi (problema N+1: carica una sola volta, non una per messaggio)
    # .find(id) = SELECT * WHERE id = id, SOLLEVA RecordNotFound se non trova (diverso da find_by che ritorna nil)
    conversation = Conversation.includes(:messages).find(params[:id])

    # .present? = contrario di .blank? (verifica se valore esiste e non è vuoto)
    # .to_s = converti a stringa (company_id è Integer, params[:company_id] è String)
    # Controlla autorizzazione: l'azienda nel token corrisponde a quella della conversazione
    if params[:company_id].present? && conversation.company_id.to_s != params[:company_id].to_s
      return render json: { error: "Non hai accesso a questa conversazione" }, status: :forbidden
    end

    # Delega a metodo privato che trasforma la conversazione in struttura JSON
    render json: conversation_payload(conversation), status: :ok
  rescue ActiveRecord::RecordNotFound
    # find() solleva ActiveRecord::RecordNotFound, lo catturiamo qui
    render json: { error: "Conversazione non trovata" }, status: :not_found
  end

  # GET /conversazioni/ricerca?q=term&company_id=:id
  # Ricerca conversazioni per testo nel titolo, summary o messaggi
  def search_conversations
    # .presence = ritorna il valore se presente/non vuoto, altrimenti nil
    # A || B = usa A se presente, altrimenti prova B (supporta q o query come parametro)
    term = params[:q].presence || params[:query].presence
    return render json: { error: "Parametro di ricerca mancante" }, status: :bad_request if term.blank?

    # .left_outer_joins(:messages) = INNER JOIN ma mantiene righe anche senza messaggi (LEFT JOIN in SQL)
    conversations = Conversation.left_outer_joins(:messages)
    # Query chainabile: applica WHERE solo se company_id è fornito
    conversations = conversations.where(company_id: params[:company_id]) if params[:company_id].present?

    # Prepara pattern per ricerca LIKE (PostgreSQL ILIKE = case insensitive, contrario di LIKE)
    like = "%#{term}%"
    # WHERE (A ILIKE term) OR (B ILIKE term) OR (C ILIKE term) con parametri vincolati (:term) per prevenire SQL injection
    conversations = conversations.where(
      "conversations.title ILIKE :term OR conversations.summary ILIKE :term OR messages.content ILIKE :term",
      term: like
    # .distinct = DISTINCT (rimuove duplicati causati dal LEFT JOIN, altrimenti una conversazione appare una volta per messaggio)
    # .order(updated_at: :desc) = ordina per data decrescente
    # .limit(50) = carica max 50 risultati
    ).distinct.order(updated_at: :desc).limit(50)

    render json: {
      total: conversations.size,
      # .map { |c| ... } = trasforma ogni conversazione in un piccolo hash JSON (come forEach in JS)
      conversations: conversations.map do |c|
        {
          id: c.id,
          title: c.title,
          summary: c.summary,
          # .iso8601 = formatta timestamp in standard ISO8601 (es: 2026-01-05T15:30:00.000Z)
          updated_at: c.updated_at.iso8601
        }
      end
    }, status: :ok
  end

  # POST /genera-immagine
  # Genera un'immagine usando Amazon Bedrock Nova Canvas
  #
  # Input (JSON body o form params):
  #   - prompt (String, required): descrizione dell'immagine da generare
  #   - company_id (Integer, required): ID azienda per ownership e tracciamento
  #   - conversation_id (Integer, optional): ID conversazione testuale da associare
  #        Se fornito, ELIMINA le immagini precedenti della stessa conversazione
  #        Politica: 1 sola immagine per conversazione, l'ultima sovrascrive
  #   - width (Integer, default 1024): larghezza in pixel (valori: 1024, 1280, 720)
  #   - height (Integer, default 1024): altezza in pixel (valori: 1024, 720, 1280)
  #   - seed (Integer, optional): seed per riproducibilità
  #        Omesso = generazione casuale (seed random 0-2147483647)
  #        Fornito = riproducibile (stesso seed + stesso prompt = stessa immagine)
  #
  # Output JSON (201 Created):
  #   {
  #     "image_url": "/rails/active_storage/.../nova_123_456789.png",
  #     "image_id": 123,
  #     "width": 1024,
  #     "height": 1024,
  #     "model_id": "amazon.nova-canvas-v1:0",
  #     "created_at": "2026-01-05T15:30:00.000Z"
  #   }
  #
  # Errori possibili:
  #   - 422 Unprocessable: parametri mancanti, dimensioni non supportate
  #   - 404 Not Found: company_id inesistente
  #   - 500 Internal Server Error: errori Bedrock API, network, bug
  #
  # Esempi dimensioni valide:
  #   - 1024x1024 (quadrato): icone, avatar, post social
  #   - 1280x720 (16:9 landscape): banner, copertine, video thumbnail
  #   - 720x1280 (9:16 portrait): stories Instagram/TikTok, mobile vertical
  def create_image
    # Estrae i parametri dalla richiesta HTTP (query string o JSON body)
    # params è un hash di stringhe fornito da Rails ActionController
    prompt = params[:prompt]
    company_id = params[:company_id]
    conversation_id = params[:conversation_id] # opzionale: assegnare l'immagine a una conversazione
    
    # Dimensioni con fallback a 1024x1024 se non forniti
    # .present? ? A : B = ternario: se presente allora A, altrimenti B
    # .to_i = converte stringa a intero ("1024" -> 1024)
    width = params[:width].present? ? params[:width].to_i : 1024
    height = params[:height].present? ? params[:height].to_i : 1024
    
    # Seed opzionale: nil = generazione casuale, int = generazione deterministica
    seed = params[:seed].present? ? params[:seed].to_i : nil

    # Validazione preliminare: prompt e company_id sono SEMPRE richiesti
    if prompt.blank? || company_id.blank?
      return render json: { error: "prompt e company_id sono obbligatori" }, status: :unprocessable_entity
    end

    # Delega la logica complessa a ImageService (service layer, non nel controller)
    # ImageService si occupa di:
    #   1. Validare dimensioni (solo 1024x1024, 1280x720, 720x1280 supportate da Bedrock)
    #   2. Inviare richiesta ad AWS Bedrock Nova Canvas API
    #   3. Eliminare immagini precedenti della stessa conversazione (politica: 1 per conversazione)
    #   4. Salvare il record nel DB (tabella generated_images)
    #   5. Uploadare l'immagine su ActiveStorage (file system gestito da Rails)
    result = ImageService.new.genera(
      prompt: prompt,
      company_id: company_id,
      conversation_id: conversation_id,
      width: width,
      height: height,
      seed: seed
    )

    # Recupera l'oggetto immagine dal risultato del servizio
    generated_image = result[:generated_image_object]
    # .image = associazione ActiveStorage (file allegato al record GeneratedImage)
    # .attached? = verifica che il file sia stato caricato
    # rails_blob_path = genera URL temporaneo FIRMATO per accedere al blob (sicurezza: solo utenti autorizzati)
    # disposition: "inline" = URL serve il file inline (mostra nel browser) invece di download
    image_url = rails_blob_path(generated_image.image, disposition: "inline") if generated_image.image.attached?

    # Risposta JSON con tutti i metadati rilevanti
    render json: {
      image_url: image_url,          # URL firmato temporaneo per visualizzare l'immagine
      image_id: generated_image.id,  # ID del record nel DB (per future query)
      width: result[:width],          # Conferma delle dimensioni effettive (in pixel)
      height: result[:height],
      model_id: result[:model_id],   # ID del modello Bedrock usato (es: amazon.nova-canvas-v1:0)
      # .iso8601 = formatta il timestamp in standard internazionale (2026-01-05T15:30:00.000Z)
      created_at: generated_image.created_at.iso8601
    }, status: :created # HTTP 201 = risorsa creata con successo

  # Gestione errori specifici per diversi scenari
  # rescue TYPE => e = cattura eccezioni di tipo TYPE e le salva in e
  rescue ArgumentError => e
    # Sollevato da ImageService quando le dimensioni non sono supportate
    # Es: "Dimensioni non supportate per Nova Canvas. Usa: 1024x1024, 1280x720, 720x1280"
    # HTTP 422 = Unprocessable Entity (parametri ricevuti ma non elaborabili)
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    # Sollevato da find() quando il record non esiste
    # Significa che company_id fornito non esiste nel database
    # HTTP 404 = Not Found
    render json: { error: "Azienda non trovata" }, status: :not_found
  rescue => e
    # rescue senza tipo = cattura TUTTE le eccezioni rimanenti (fallback generico)
    # Es: Bedrock API down, network timeout, bug inaspettato, credenziali AWS non valide
    # Logga lo stacktrace completo per debug in produzione
    # "#{e.backtrace.join("\\n")}" = stack trace multiriga (quando errore viene segnalato)
    Rails.logger.error "Errore generazione immagine: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    # HTTP 500 = Internal Server Error (errore del server, non del client)
    render json: { error: "Errore interno: #{e.message}" }, status: :internal_server_error
  end

  private
  # Metodi privati: usabili solo internamente al controller, non via HTTP

  def conversation_payload(conversation)
    # Trasforma un oggetto Conversation (con i suoi messaggi) in una struttura hash per JSON
    # Questo è un "payload builder" che centralizza il formato di risposta
    {
      id: conversation.id,
      company_id: conversation.company_id,
      title: conversation.title,
      summary: conversation.summary,
      # .iso8601 = converte timestamp ActiveRecord a stringa ISO8601 standard (utile per JS/frontend)
      created_at: conversation.created_at.iso8601,
      updated_at: conversation.updated_at.iso8601,
      # .order(:created_at) = ordina messaggi per data crescente (più vecchi prima)
      # .map do |msg| ... end = itera ogni messaggio e trasformalo in mini-hash JSON
      messages: conversation.messages.order(:created_at).map do |msg|
        {
          id: msg.id,
          role: msg.role,        # "user" o "assistant"
          content: msg.content,   # il testo del messaggio
          created_at: msg.created_at.iso8601
        }
      end
    }
  end
end
