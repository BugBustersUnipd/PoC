class ImagesController < ActionController::API
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
  def index
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
  def show
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
end