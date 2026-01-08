class ImageGenerationController < ActionController::API
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
  def create
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
    image_service = DiContainer.image_service
    result = image_service.genera(
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
end