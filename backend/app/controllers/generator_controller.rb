class GeneratorController < ActionController::API
  # POST /genera
  def create
    prompt     = params[:prompt]
    tone_name  = params[:tone]
    company_id = params[:company_id]
    conversation_id = params[:conversation_id]

    if prompt.blank? || tone_name.blank? || company_id.blank?
      return render json: { error: "prompt, tone e company_id sono obbligatori" }, status: :unprocessable_entity
    end

    result = AiService.new.genera(prompt, company_id, tone_name, conversation_id: conversation_id)
    render json: result, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Record non trovato: #{e.message}"
    render json: { error: "Azienda, tono o conversazione non trovati" }, status: :not_found
  rescue => e
    Rails.logger.error "Errore interno: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Errore interno: #{e.message}" }, status: :internal_server_error
  end

  # GET /toni?company_id=:id
  def index
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    company = Company.find_by(id: company_id)
    return render json: { error: "Azienda non trovata" }, status: :not_found unless company

    tones = company.tones.select(:id, :name, :instructions)
    render json: {
      company: { id: company.id, name: company.name },
      tones: tones
    }, status: :ok
  end

  # GET /conversazioni?company_id=:id
  def conversations
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    conversations = Conversation.where(company_id: company_id).order(updated_at: :desc).limit(50)
    render json: conversations.as_json(only: [ :id, :title, :created_at, :updated_at, :summary ])
  end

  # GET /conversazioni/:id
  def show_conversation
    conversation = Conversation.includes(:messages).find(params[:id])

    if params[:company_id].present? && conversation.company_id.to_s != params[:company_id].to_s
      return render json: { error: "Non hai accesso a questa conversazione" }, status: :forbidden
    end

    render json: conversation_payload(conversation), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Conversazione non trovata" }, status: :not_found
  end

  # GET /conversazioni/ricerca?q=term&company_id=:id
  # Restituisce gli id (e pochi metadati) delle conversazioni che contengono il testo
  def search_conversations
    term = params[:q].presence || params[:query].presence
    return render json: { error: "Parametro di ricerca mancante" }, status: :bad_request if term.blank?

    conversations = Conversation.left_outer_joins(:messages)
    conversations = conversations.where(company_id: params[:company_id]) if params[:company_id].present?

    like = "%#{term}%"
    conversations = conversations.where(
      "conversations.title ILIKE :term OR conversations.summary ILIKE :term OR messages.content ILIKE :term",
      term: like
    ).distinct.order(updated_at: :desc).limit(50)

    render json: {
      total: conversations.size,
      conversations: conversations.map do |c|
        {
          id: c.id,
          title: c.title,
          summary: c.summary,
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
    # Estrae parametri dalla request
    prompt = params[:prompt]
    company_id = params[:company_id]
    conversation_id = params[:conversation_id] # optional - associa a conversazione testuale
    
    # Dimensioni con default 1024x1024 (quadrato standard)
    width = params[:width].present? ? params[:width].to_i : 1024
    height = params[:height].present? ? params[:height].to_i : 1024
    
    # Seed optional: nil = casuale, fornito = riproducibile
    seed = params[:seed].present? ? params[:seed].to_i : nil

    # Validazione parametri obbligatori
    if prompt.blank? || company_id.blank?
      return render json: { error: "prompt e company_id sono obbligatori" }, status: :unprocessable_entity
    end

    # Delega generazione al servizio
    # ImageService si occupa di:
    #   1. Validare dimensioni (solo 1024x1024, 1280x720, 720x1280)
    #   2. Chiamare Bedrock Nova Canvas con invoke_model API
    #   3. Eliminare immagini precedenti della conversazione (se conversation_id presente)
    #   4. Salvare nel DB (GeneratedImage) + disco (ActiveStorage)
    result = ImageService.new.genera(
      prompt: prompt,
      company_id: company_id,
      conversation_id: conversation_id,
      width: width,
      height: height,
      seed: seed
    )

    # Genera URL pubblico per accedere all'immagine
    # rails_blob_path crea URL temporaneo firmato per sicurezza
    # disposition: inline = mostra nel browser invece di scaricare
    generated_image = result[:generated_image_object]
    image_url = rails_blob_path(generated_image.image, disposition: "inline") if generated_image.image.attached?

    # Response JSON con tutti i metadati
    render json: {
      image_url: image_url,          # URL visualizzazione (firmato, temporaneo)
      image_id: generated_image.id,  # ID record DB per future referenze
      width: result[:width],          # Dimensioni effettive (conferma input)
      height: result[:height],
      model_id: result[:model_id],   # Modello Bedrock usato (es. amazon.nova-canvas-v1:0)
      created_at: generated_image.created_at.iso8601 # Timestamp ISO8601 standard
    }, status: :created # 201 Created

  # Gestione errori strutturata per diversi scenari
  rescue ArgumentError => e
    # Dimensioni non supportate o parametri invalidi
    # Es: "Dimensioni non supportate per Nova Canvas. Usa: 1024x1024, 1280x720, 720x1280"
    render json: { error: e.message }, status: :unprocessable_entity # 422
  rescue ActiveRecord::RecordNotFound
    # company_id non esiste nel database
    render json: { error: "Azienda non trovata" }, status: :not_found # 404
  rescue => e
    # Errori imprevisti: Bedrock API down, network issues, bug nel codice
    # Log completo con stacktrace per facilitare debug
    Rails.logger.error "Errore generazione immagine: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Errore interno: #{e.message}" }, status: :internal_server_error # 500
  end

  # GET /immagini?company_id=:id
  # Recupera tutte le immagini generate da una compagnia
  #
  # Input (query):
  #   - company_id (Integer, required): ID azienda
  #   - limit (Integer, optional, default 50): numero massimo immagini da restituire
  #   - offset (Integer, optional, default 0): offset per paginazione
  #   - conversation_id (Integer, optional): filtra per una conversazione specifica
  #
  # Output JSON (200 OK):
  #   {
  #     "total": 15,
  #     "images": [
  #       {
  #         "id": 123,
  #         "prompt": "Un tramonto rosso sulla spiaggia",
  #         "width": 1024,
  #         "height": 1024,
  #         "model_id": "amazon.nova-canvas-v1:0",
  #         "image_url": "/rails/active_storage/blobs/...",
  #         "conversation_id": 456,
  #         "created_at": "2026-01-05T15:30:00.000Z"
  #       }
  #     ]
  #   }
  def list_images
    company_id = params[:company_id]
    limit = (params[:limit] || 50).to_i.clamp(1, 100)
    offset = (params[:offset] || 0).to_i.clamp(0, 10000)

    # Validazione parametri obbligatori
    if company_id.blank?
      return render json: { error: "company_id è obbligatorio" }, status: :bad_request
    end

    # Verifica che l'azienda esista
    company = Company.find_by(id: company_id)
    unless company
      return render json: { error: "Azienda non trovata" }, status: :not_found
    end

    # Costruisce la query base
    query = GeneratedImage.where(company_id: company_id)

    # Filtro opzionale per conversazione
    if params[:conversation_id].present?
      query = query.where(conversation_id: params[:conversation_id])
    end

    # Conteggio totale (prima della paginazione)
    total = query.count

    # Applica paginazione e ordinamento (più recenti prima)
    images = query
      .order(created_at: :desc)
      .limit(limit)
      .offset(offset)

    # Mappa i risultati nel formato JSON
    images_data = images.map do |img|
      {
        id: img.id,
        prompt: img.prompt,
        width: img.width,
        height: img.height,
        model_id: img.model_id,
        image_url: img.image.attached? ? rails_blob_path(img.image, disposition: "inline") : nil,
        conversation_id: img.conversation_id,
        created_at: img.created_at.iso8601
      }
    end

    render json: {
      total: total,
      limit: limit,
      offset: offset,
      images: images_data
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Azienda non trovata" }, status: :not_found
  rescue => e
    Rails.logger.error "Errore recupero immagini: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Errore interno: #{e.message}" }, status: :internal_server_error
  end

  # GET /immagini/:id
  # Recupera i dettagli di una singola immagine
  #
  # Input (path e query):
  #   - id (Integer, required path): ID immagine
  #   - company_id (Integer, optional): per verifica ownership (ritorna 403 se non corrisponde)
  #
  # Output JSON (200 OK):
  #   {
  #     "id": 123,
  #     "prompt": "Un tramonto rosso sulla spiaggia",
  #     "width": 1024,
  #     "height": 1024,
  #     "model_id": "amazon.nova-canvas-v1:0",
  #     "image_url": "/rails/active_storage/blobs/...",
  #     "company_id": 42,
  #     "conversation_id": 456,
  #     "created_at": "2026-01-05T15:30:00.000Z"
  #   }
  def show_image
    image = GeneratedImage.find(params[:id])

    # Verifica ownership opzionale: se company_id è fornito, verifica corrispondenza
    if params[:company_id].present? && image.company_id.to_s != params[:company_id].to_s
      return render json: { error: "Non hai accesso a questa immagine" }, status: :forbidden
    end

    render json: {
      id: image.id,
      prompt: image.prompt,
      width: image.width,
      height: image.height,
      model_id: image.model_id,
      image_url: image.image.attached? ? rails_blob_path(image.image, disposition: "inline") : nil,
      company_id: image.company_id,
      conversation_id: image.conversation_id,
      created_at: image.created_at.iso8601
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Immagine non trovata" }, status: :not_found
  rescue => e
    Rails.logger.error "Errore recupero immagine: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Errore interno: #{e.message}" }, status: :internal_server_error
  end

  private

  def conversation_payload(conversation)
    {
      id: conversation.id,
      company_id: conversation.company_id,
      title: conversation.title,
      summary: conversation.summary,
      created_at: conversation.created_at.iso8601,
      updated_at: conversation.updated_at.iso8601,
      messages: conversation.messages.order(:created_at).map do |msg|
        {
          id: msg.id,
          role: msg.role,
          content: msg.content,
          created_at: msg.created_at.iso8601
        }
      end
    }
  end
end
