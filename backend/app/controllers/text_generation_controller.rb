# TextGenerationController - Gestisce le richieste di generazione testo via AI
#
# Endpoint: POST /genera
# Input: { prompt, tone, company_id, conversation_id (optional) }
# Output: { text, conversation_id }
#
# Questo controller:
# - Valida i parametri di input tramite TextGenerationParams
# - Delega la logica di business ad AiService
# - Serializza la risposta tramite TextGenerationSerializer
# - Gestisce errori HTTP appropriati
class TextGenerationController < ApplicationController
  # POST /genera
  # Genera testo usando Amazon Bedrock con contesto aziendale e tono specificato
  #
  # Flow:
  # 1. Valida e normalizza input con TextGenerationParams
  # 2. Delega generazione ad AiService (che orchestra prompt, API, persistenza)
  # 3. Serializza output JSON
  # 4. Gestisce errori con codici HTTP appropriati
  def create
    # Pattern Ruby: named parameters (prompt:, tone_name:, etc.)
    # params[] accede ai parametri HTTP (Rails li converte automaticamente da JSON/form-data)
    request_params = TextGenerationParams.new(
      prompt: params[:prompt],
      tone_name: params[:tone],
      company_id: params[:company_id],
      conversation_id: params[:conversation_id]
    )

    # Validazione early return: blocca richiesta se parametri invalidi
    # unless X equivale a if !X (Ruby idiom per negazione leggibile)
    unless request_params.valid?
      return render json: { error: request_params.errors.first, errors: request_params.errors }, status: :unprocessable_entity
    end

    # Delega al service: controller non contiene logica di business
    # conversation_id: è un "keyword argument" (opzionale, default nil se omesso)
    result = ai_service.genera(
      request_params.prompt,
      request_params.company_id,
      request_params.tone_name,
      conversation_id: request_params.conversation_id
    )

    # render json: ... serializza automaticamente Hash in JSON e invia response HTTP
    # status: :ok → HTTP 200
    render json: TextGenerationSerializer.serialize(
      text: result[:text],           # result è Hash con simboli come chiavi
      conversation_id: result[:conversation_id]
    ), status: :ok

  # rescue cattura eccezioni (equivalente a try-catch in altri linguaggi)
  # => e cattura l'oggetto eccezione in variabile e
  rescue ActiveRecord::RecordNotFound => e
    # Lanciato da Company.find o Tone.find quando ID non esiste
    Rails.logger.error "Record non trovato: #{e.message}"
    render json: { error: "Azienda, tono o conversazione non trovati" }, status: :not_found
  rescue Aws::BedrockRuntime::Errors::ThrottlingException => e
    # Errore quota superata Bedrock
    Rails.logger.error "Bedrock throttling: #{e.message}"
    render json: { error: "Troppe richieste simultanee. Riprova tra qualche secondo." }, status: :too_many_requests
  rescue Aws::BedrockRuntime::Errors::AccessDeniedException => e
    # Errore accesso Bedrock (modello non disponibile, permessi)
    Rails.logger.error "Bedrock access denied: #{e.message}"
    render json: { error: "Servizio temporaneamente non disponibile. Riprova più tardi." }, status: :service_unavailable
  rescue => e
    # rescue senza classe cattura tutte le eccezioni (fallback generico)
    # Utile per errori imprevisti: API down, network timeout, bug
    Rails.logger.error "Errore interno: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Errore interno: #{e.message}" }, status: :internal_server_error
  end
end