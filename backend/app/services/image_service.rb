require "aws-sdk-bedrockruntime"
require "json"
require "base64"

# ImageService
# - Servizio per generare immagini usando Amazon Bedrock Nova Canvas
# - Gestisce il ciclo completo: validazione, chiamata API, salvataggio con ActiveStorage
# - Elimina automaticamente immagini precedenti della stessa conversazione (1 sola immagine per conversazione)
# - Configurazione caricata da bedrock.yml via BEDROCK_CONFIG_IMAGE_GENERATION
class ImageService
  # Usa la configurazione da bedrock.yml caricata nell'initializer
  # Include: region, model_id (es. amazon.nova-canvas-v1:0)
  BEDROCK_CONFIG = ::BEDROCK_CONFIG_IMAGE_GENERATION

  # Nova Canvas supporta solo risoluzioni specifiche
  # Altre dimensioni causeranno errore di validazione
  VALID_SIZES = [
    { w: 1024, h: 1024 }, # 1:1 Square - Ideale per icone, avatar, post social
    { w: 1280, h: 720 },  # 16:9 Landscape - Banner, copertine, video thumbnail
    { w: 720, h: 1280 }   # 9:16 Portrait - Stories Instagram, TikTok, mobile vertical
  ].freeze

  def initialize
    @region = BEDROCK_CONFIG["region"]
    # Client AWS Bedrock Runtime per invocare il modello
    # Usa le credenziali da ENV (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN)
    @client = Aws::BedrockRuntime::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"],
      region: @region
    )
  end

  # Genera un'immagine usando Nova Canvas
  # 
  # Parametri:
  #   prompt: (String, required) Descrizione dell'immagine da generare
  #   company_id: (Integer, required) ID azienda per tracciamento e ownership
  #   conversation_id: (Integer, optional) ID conversazione testuale da associare
  #   width: (Integer, default 1024) Larghezza immagine in pixel
  #   height: (Integer, default 1024) Altezza immagine in pixel
  #   seed: (Integer, optional) Seed per riproducibilità (stesso seed = stessa immagine)
  #
  # Ritorna Hash con:
  #   - generated_image_object: oggetto GeneratedImage salvato nel DB
  #   - width, height, seed, model_id: metadati della generazione
  #
  # Raises:
  #   ArgumentError se dimensioni non supportate o parametri invalidi
  #   ActiveRecord::RecordNotFound se company_id non esiste
  def genera(prompt:, company_id:, conversation_id: nil, width: 1024, height: 1024, seed: nil)
    # Valida che le dimensioni siano tra quelle supportate da Nova Canvas
    validate_size!(width, height)
    
    company = Company.find(company_id)
    model_id = BEDROCK_CONFIG["model_id"]
    
    # Nova gestisce i seed tra 0 e 2147483647 (max signed int32)
    # Seed = riproducibilità: stesso seed + stesso prompt = stessa immagine
    actual_seed = seed.present? ? seed.to_i : rand(0..2_147_483_647)

    # Costruiamo il payload JSON specifico per Nova Canvas
    body = build_nova_payload(prompt, width, height, actual_seed)

    Rails.logger.info("NovaCanvas: Generazione [#{width}x#{height}] Seed: #{actual_seed}")

    # Chiama Bedrock con invoke_model (Nova Canvas usa questo, non Converse)
    response = invoke_bedrock(model_id, body)
    
    # Estrae l'immagine base64 dal response JSON di Bedrock
    image_data = extract_image_data(response)

    # Salva nel DB e su disco (con ActiveStorage)
    # Se conversation_id già ha un'immagine, viene prima eliminata
    generated_image = save_generated_image(
      company: company,
      prompt: prompt,
      image_data: image_data,
      width: width,
      height: height,
      model_id: model_id,
      conversation_id: conversation_id,
      seed: actual_seed
    )

    # Ritorna metadati + oggetto per uso nel controller
    {
      image_url: nil, # Verrà generato dal controller con rails_blob_path
      generated_image_object: generated_image,
      width: width,
      height: height,
      seed: actual_seed,
      model_id: model_id
    }
  end

  private

  # Valida che width/height siano tra le combinazioni supportate da Nova Canvas
  # Raises ArgumentError con lista dimensioni valide se non supportate
  def validate_size!(width, height)
    is_valid = VALID_SIZES.any? { |s| s[:w] == width && s[:h] == height }
    
    unless is_valid
      allowed = VALID_SIZES.map { |s| "#{s[:w]}x#{s[:h]}" }.join(", ")
      raise ArgumentError, "Dimensioni non supportate per Nova Canvas. Usa: #{allowed}"
    end
  end

  # Costruisce il payload JSON per Nova Canvas secondo le specifiche API
  # 
  # Nova Canvas richiede:
  #   - taskType: "TEXT_IMAGE" per generazione da testo
  #   - textToImageParams: prompt principale + negative prompt (cosa evitare)
  #   - imageGenerationConfig: dimensioni, numero immagini, cfgScale (creatività), seed
  #
  # cfgScale = 7.0 è un ottimo bilanciamento tra fedeltà al prompt e qualità visiva
  # negative prompt aiuta a evitare artefatti comuni (watermark, blur, testo indesiderato)
  def build_nova_payload(prompt, width, height, seed)
    {
      taskType: "TEXT_IMAGE",
      textToImageParams: {
        text: prompt,
        # Negative prompt: istruisce il modello su cosa NON includere
        # Migliora la qualità finale evitando difetti comuni
        negativeText: "low quality, bad anatomy, distorted, watermark, text, signature, blur, grainy"
      },
      imageGenerationConfig: {
        numberOfImages: 1,
        height: height,
        width: width,
        cfgScale: 7.0, # Classifier-Free Guidance: 7.0 = ottimo bilanciamento creatività/fedeltà
        seed: seed
      }
    }.to_json
  end

  # Invoca Bedrock con invoke_model (non Converse)
  # Nova Canvas non supporta l'API Converse, usa invoke_model con payload JSON custom
  #
  # Gestisce errori comuni:
  #   - ValidationException: parametri invalidi (dimensioni sbagliate, seed out of range)
  #   - ServiceError: errori lato AWS (throttling, access denied, model non abilitato)
  def invoke_bedrock(model_id, body)
    @client.invoke_model(
      model_id: model_id,
      body: body,
      content_type: "application/json",
      accept: "application/json"
    )
  rescue Aws::BedrockRuntime::Errors::ValidationException => e
    Rails.logger.error("Errore validazione parametri Nova: #{e.message}")
    raise ArgumentError, "Parametri non validi per il modello (controlla dimensioni/seed)"
  rescue Aws::BedrockRuntime::Errors::ServiceError => e
    Rails.logger.error("Bedrock API Error: #{e.code} - #{e.message}")
    raise
  end

  # Estrae l'immagine base64 dal response JSON di Bedrock
  # 
  # Nova Canvas può ritornare l'immagine in diversi formati a seconda della versione:
  #   - images: array di stringhe base64 (formato comune Titan/Nova)
  #   - image: stringa base64 diretta
  #   - image_base64 o imageUriBase64: varianti meno comuni
  #
  # Logga il payload completo per debug se formato non riconosciuto
  def extract_image_data(response)
    payload = JSON.parse(response.body.read)
    
    Rails.logger.info("Nova Canvas Response keys: #{payload.keys.join(', ')}")
    
    # Prova diversi formati di response per massima compatibilità
    if payload["images"]&.any?
      payload["images"].first
    elsif payload["image"]
      payload["image"]
    elsif payload["image_base64"]
      payload["image_base64"]
    elsif payload["imageUriBase64"]
      payload["imageUriBase64"]
    else
      # Nessun formato riconosciuto: logga tutto per debug e solleva errore
      Rails.logger.error("Nova Canvas: Response non contenente immagine. Payload completo: #{payload.inspect}")
      raise "Errore Nova Canvas: Nessuna immagine ritornata. Payload keys: #{payload.keys.join(', ')}"
    end
  end

  # Salva l'immagine nel DB (GeneratedImage) e su disco (ActiveStorage)
  # 
  # IMPORTANTE: Se conversation_id già ha un'immagine associata, viene ELIMINATA
  # Questo garantisce 1 sola immagine per conversazione (l'ultima generata sovrascrive)
  #
  # Flow:
  #   1. Elimina vecchie immagini della stessa conversazione (record DB + file disco)
  #   2. Crea nuovo record GeneratedImage nel DB
  #   3. Decodifica base64 → bytes
  #   4. Attach immagine con ActiveStorage (salva su disk locale o S3)
  #   5. Ritorna oggetto GeneratedImage completo
  def save_generated_image(company:, prompt:, image_data:, width:, height:, model_id:, conversation_id:, seed:)
    # Elimina immagini precedenti per questa conversazione (se esiste)
    # dependent: :destroy su has_one_attached elimina anche i file fisici
    if conversation_id.present?
      GeneratedImage.where(conversation_id: conversation_id).destroy_all
      Rails.logger.info("Immagini precedenti per conversation_id=#{conversation_id} eliminate")
    end

    # Crea record nel DB
    generated_image = GeneratedImage.create!(
      company: company,
      prompt: prompt,
      conversation_id: conversation_id,
      width: width,
      height: height,
      model_id: model_id
    )

    # Decodifica base64 → binary PNG
    image_bytes = Base64.decode64(image_data)
    
    # Attach file con ActiveStorage
    # Salvataggio: config/storage.yml → local in dev, S3 in prod
    # Filename include ID e seed per tracciabilità e debug
    generated_image.image.attach(
      io: StringIO.new(image_bytes),
      filename: "nova_#{generated_image.id}_#{seed}.png",
      content_type: "image/png"
    )

    generated_image
  end
end
