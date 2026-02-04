class ImageGenerationController < ApplicationController
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
  
  def create
    # Pattern: validazione tramite value object dedicato (SRP)
    # ImageGenerationParams normalizza input (defaults) e valida requisiti
    request_params = ImageGenerationParams.new(
      prompt: params[:prompt],
      company_id: params[:company_id],
      conversation_id: params[:conversation_id],
      width: params[:width],
      height: params[:height],
      seed: params[:seed]
    )

    # Guard clause: blocca richiesta se validazione fallisce
    unless request_params.valid?
      return render json: { error: request_params.errors.first, errors: request_params.errors }, status: :unprocessable_entity
    end

    # Delega generazione al servizio orchestratore
    # ImageService coordina: validazione dimensioni, generazione API, storage
    # **request_params.to_service_params è "splat operator":
    # converte Hash {prompt: \"x\", width: 1024, ...} in keyword arguments (prompt: \"x\", width: 1024, ...)
    # Equivalente a: image_service.genera(prompt: request_params.prompt, width: request_params.width, ...)
    #   1. Validare dimensioni (solo 1024x1024, 1280x720, 720x1280)
    #   2. Chiamare Bedrock Nova Canvas con invoke_model API
    #   3. Eliminare immagini precedenti della conversazione (se conversation_id presente)
    #   4. Salvare nel DB (GeneratedImage) + disco (ActiveStorage)
    result = image_service.genera(**request_params.to_service_params)

    # Genera URL pubblico per accedere all'immagine
    # rails_blob_path crea URL temporaneo firmato per sicurezza
    # disposition: inline = mostra nel browser invece di scaricare
    generated_image = result[:generated_image_object]
    image_url = rails_blob_path(generated_image.image, disposition: "inline") if generated_image.image.attached?

    # Response JSON con tutti i metadati
    render json: GeneratedImageSerializer.serialize(
      generated_image: generated_image,
      image_url: image_url,
      width: result[:width],
      height: result[:height],
      model_id: result[:model_id]
    ), status: :created # 201 Created

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