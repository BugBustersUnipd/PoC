require "aws-sdk-bedrockruntime"
require "json"
require "base64"

# ImageService: servizio per generare immagini con Amazon Bedrock Nova Canvas
# 
# Gestisce il ciclo completo di generazione immagini:
#   1. Validazione prompt, company, dimensioni
#   2. Costruzione payload Nova Canvas
#   3. Invocazione API Bedrock
#   4. Estrazione e decodifica immagine base64
#   5. Salvataggio DB + ActiveStorage
#   6. Pulizia immagini precedenti (1 per conversazione)
#
# FLUSSO TIPICO:
#   1. GeneratorController.create_image(prompt, company_id, width, height)
#   2. ImageService.genera() valida e invia richiesta a Bedrock
#   3. Bedrock genera PNG, ritorna base64
#   4. Service salva nel DB (GeneratedImage) e su disco (ActiveStorage)
#   5. Controller ritorna URL firmato alla immagine
#
# POLITICA 1 IMMAGINE PER CONVERSAZIONE:
#   - Se conversation_id fornito: elimina immagini precedenti della stessa conversation
#   - Garantisce che una chat abbia max 1 immagine (l'ultima generazione)
#   - Riduce storage, semplifica UX (una immagine per chiacchierata)
class ImageService
  # Carica configurazione da bedrock.yml via initializer
  # Include: region (us-east-1), model_id (amazon.nova-canvas-v1:0), temperature, max_tokens
  BEDROCK_CONFIG = ::BEDROCK_CONFIG_IMAGE_GENERATION

  # Nova Canvas supporta SOLO queste risoluzioni (definite da AWS)
  # Altre dimensioni causeranno errore ValidationException da Bedrock
  # .freeze = immutabile (prevent accidental modification)
  VALID_SIZES = [
    { w: 1024, h: 1024 }, # 1:1 Square - Ideale per icone, avatar, post social
    { w: 1280, h: 720 },  # 16:9 Landscape - Banner, copertine, video thumbnail
    { w: 720, h: 1280 }   # 9:16 Portrait - Stories Instagram, TikTok, mobile vertical
  ].freeze

  def initialize
    # Legge regione da configurazione
    @region = BEDROCK_CONFIG["region"]
    
    # Crea client AWS Bedrock Runtime per invocare modello
    # Usa le credenziali da ENV (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN)
    # In prod: usa IAM role (env vars non servono)
    @client = Aws::BedrockRuntime::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"],
      region: @region
    )
  end

  # Genera un'immagine usando Amazon Bedrock Nova Canvas
  # 
  # Parametri (keyword arguments):
  #   prompt (String, required): descrizione dell'immagine da generare
  #     Es: "Un gatto che suona il pianoforte in stile Van Gogh"
  #   company_id (Integer, required): ID azienda (ownership, tracciamento)
  #   conversation_id (Integer, optional): ID conversazione da associare
  #     Se fornito: elimina immagini precedenti della stessa conversazione
  #   width (Integer, default 1024): larghezza pixel (valori: 1024, 1280, 720)
  #   height (Integer, default 1024): altezza pixel (valori: 1024, 720, 1280)
  #   seed (Integer, optional): seed per riproducibilità
  #     Se nil: generazione casuale (seed random 0-2147483647)
  #     Se int: deterministica (stesso seed + prompt = stessa immagine)
  #
  # Ritorna:
  #   {
  #     image_url: nil,  # Verrà generato dal controller con rails_blob_path
  #     generated_image_object: GeneratedImage,  # Record DB salvato
  #     width: 1024,
  #     height: 1024,
  #     seed: 123456,
  #     model_id: "amazon.nova-canvas-v1:0"
  #   }
  #
  # Raises:
  #   ArgumentError: dimensioni non supportate, parametri invalidi
  #   ActiveRecord::RecordNotFound: company_id non esiste
  #   Aws::BedrockRuntime::Errors::*: errori API Bedrock
  def genera(prompt:, company_id:, conversation_id: nil, width: 1024, height: 1024, seed: nil)
    # Valida che le dimensioni siano tra quelle supportate da Nova Canvas
    # Solleva ArgumentError se non valide
    validate_size!(width, height)
    
    # Carica company dal DB (solleva RecordNotFound se non esiste)
    company = Company.find(company_id)
    
    # Legge model ID dalla configurazione (es: "amazon.nova-canvas-v1:0")
    model_id = BEDROCK_CONFIG["model_id"]
    
    # Gestisce il seed:
    #   - Se fornito: usa quello (determinismo)
    #   - Se nil: genera casuale tra 0 e 2147483647 (max int32 signed)
    # .present? = contrario di .blank? (valida se valore non è nil/vuoto)
    # .to_i = converte a intero (string "123" → 123)
    actual_seed = seed.present? ? seed.to_i : rand(0..2_147_483_647)

    # Costruisce il payload JSON specifico per Nova Canvas API
    # Formato richiesto: taskType, textToImageParams, imageGenerationConfig
    body = build_nova_payload(prompt, width, height, actual_seed)

    # Log informativo per debug/tracking
    Rails.logger.info("NovaCanvas: Generazione [#{width}x#{height}] Seed: #{actual_seed}")

    # Invoca Bedrock con invoke_model (non Converse)
    # Nova Canvas non supporta Converse API, usa invoke_model con JSON body custom
    response = invoke_bedrock(model_id, body)
    
    # Estrae l'immagine base64 dalla risposta JSON di Bedrock
    # Response può avere diversi formati (images, image, image_base64, ecc.)
    image_data = extract_image_data(response)

    # Salva record nel DB e file su disco/S3 (con ActiveStorage)
    # Se conversation_id fornito: elimina immagini precedenti prima di salvare
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

    # Ritorna metadati generazione (utilizzati dal controller)
    {
      image_url: nil, # Verrà generato dal controller con rails_blob_path(generated_image.image)
      generated_image_object: generated_image,  # Oggetto DB per accesso dati completi
      width: width,
      height: height,
      seed: actual_seed,
      model_id: model_id
    }
  end

  private

  # Valida che width/height siano tra le combinazioni supportate da Nova Canvas
  # 
  # Nova Canvas è molto restrittivo: supporta SOLO 3 combinazioni
  # Qualsiasi altra dimensione → ValidationException da Bedrock
  #
  # Raises:
  #   ArgumentError: dimensioni non supportate (con lista dimensioni valide)
  def validate_size!(width, height)
    # .any? { |s| ... } = verifica se almeno uno elemento soddisfa condizione
    # s[:w] == width && s[:h] == height = trova coppia width/height nella lista
    is_valid = VALID_SIZES.any? { |s| s[:w] == width && s[:h] == height }
    
    unless is_valid
      # Costruisce lista dimensioni valide per messaggio errore
      # .map { |s| ... } = trasforma ogni elemento della lista
      # "#{s[:w]}x#{s[:h]}" = formato stringa "1024x1024", "1280x720", ecc.
      # .join(", ") = unisce array con separatore ", "
      allowed = VALID_SIZES.map { |s| "#{s[:w]}x#{s[:h]}" }.join(", ")
      raise ArgumentError, "Dimensioni non supportate per Nova Canvas. Usa: #{allowed}"
    end
  end

  # Costruisce il payload JSON per Nova Canvas secondo le specifiche API
  # 
  # Formato richiesto da Bedrock invoke_model per Nova Canvas:
  # {
  #   taskType: "TEXT_IMAGE",
  #   textToImageParams: { text: prompt, negativeText: "..." },
  #   imageGenerationConfig: { numberOfImages, width, height, cfgScale, seed }
  # }
  #
  # PARAMETRI IMPORTANTI:
  #   - cfgScale (Classifier-Free Guidance): 0-10, default 7.0
  #     * Basso (1-3): più creative ma meno fedeli al prompt
  #     * Medio (7-7.5): ottimo bilanciamento (scelto)
  #     * Alto (8-10): molto fedele al prompt, ma meno creative
  #   - negativeText: cosa EVITARE (riduce artefatti comuni)
  #   - seed: 0-2147483647 per riproducibilità
  #
  # Ritorna: JSON string (body di invoke_model)
  def build_nova_payload(prompt, width, height, seed)
    {
      taskType: "TEXT_IMAGE",  # Tipo task: text to image
      textToImageParams: {
        text: prompt,  # Descrizione dell'immagine
        # Negative prompt: istruisce modello su cosa EVITARE
        # Migliora qualità finale eliminando difetti comuni
        negativeText: "low quality, bad anatomy, distorted, watermark, text, signature, blur, grainy"
      },
      imageGenerationConfig: {
        numberOfImages: 1,  # Genera 1 immagine (potrebbe supportare >1 in futuro)
        height: height,
        width: width,
        cfgScale: 7.0,  # Classifier-Free Guidance: 7.0 = ottimo bilanciamento
        seed: seed  # Per riproducibilità
      }
    }.to_json  # Converte hash a stringa JSON per trasmissione
  end

  # Invoca Bedrock API con invoke_model (non Converse)
  # 
  # invoke_model: API basso livello per invocare il modello
  # - Input: body (payload JSON specifico per modello)
  # - Output: response JSON dal modello
  # - Non gestisce conversazioni multi-turn (usa per text-to-image, single request)
  #
  # Converse API: API alto livello per chat multi-turn
  # - Gestisce messaggi user/assistant alternati automaticamente
  # - Non supporta task type specifici (es: text-to-image)
  # - Usata per AiService (chat), non qui
  #
  # Gestisce errori:
  #   - ValidationException: parametri invalidi (dimensioni sbagliate, seed fuori range)
  #   - ServiceError: errori AWS (throttling, access denied, model non disponibile)
  def invoke_bedrock(model_id, body)
    @client.invoke_model(
      model_id: model_id,       # Es: "amazon.nova-canvas-v1:0"
      body: body,               # JSON payload (stringa)
      content_type: "application/json",  # Content type richiesta
      accept: "application/json"          # Content type risposta
    )
  # Catttura ValidationException: parametri invalidi (dimensioni, seed, ecc.)
  rescue Aws::BedrockRuntime::Errors::ValidationException => e
    Rails.logger.error("Errore validazione parametri Nova: #{e.message}")
    # Ri-solleva come ArgumentError (semantic: input non valido)
    raise ArgumentError, "Parametri non validi per il modello (controlla dimensioni/seed)"
  # Cattura altri ServiceError (throttling, access denied, model not found)
  rescue Aws::BedrockRuntime::Errors::ServiceError => e
    Rails.logger.error("Bedrock API Error: #{e.code} - #{e.message}")
    # Ri-solleva per bubbling up (il service può gestire retry)
    raise
  end

  # Estrae l'immagine base64 dal response JSON di Bedrock
  # 
  # Bedrock ritorna un JSON con l'immagine in diversi possibili formati:
  #   - images: array di stringhe base64 (formato comune per Titan/Nova)
  #   - image: singola stringa base64
  #   - image_base64 o imageUriBase64: varianti
  #
  # Questo metodo prova tutti i formati per massima compatibilità
  # (caso: Bedrock cambia formato tra versioni)
  #
  # Logga response completo se nessun formato riconosciuto (debug)
  def extract_image_data(response)
    # .read = legge il body della risposta AWS (stream → string)
    # JSON.parse = converte stringa JSON a hash Ruby
    payload = JSON.parse(response.body.read)
    
    # Log dei campi presenti nel payload (debug, tracciabilità API)
    Rails.logger.info("Nova Canvas Response keys: #{payload.keys.join(', ')}")
    
    # Prova diversi formati di risposta per massima compatibilità
    # .&.any? = safe navigation + .any? (evita NoMethodError se payload["images"] è nil)
    if payload["images"]&.any?
      payload["images"].first  # Ritorna prima immagine dell'array
    elsif payload["image"]
      payload["image"]  # Singola immagine
    elsif payload["image_base64"]
      payload["image_base64"]  # Formato alternativo
    elsif payload["imageUriBase64"]
      payload["imageUriBase64"]  # Formato alternativo
    else
      # Nessun formato riconosciuto: logga tutto per debug
      Rails.logger.error("Nova Canvas: Response non contenente immagine. Payload completo: #{payload.inspect}")
      # Solleva errore descrittivo (indica come contattare AWS support)
      raise "Errore Nova Canvas: Nessuna immagine ritornata. Payload keys: #{payload.keys.join(', ')}"
    end
  end

  # Salva l'immagine nel DB (GeneratedImage) e su disco/S3 (ActiveStorage)
  # 
  # IMPORTANTE: POLITICA 1 IMMAGINE PER CONVERSAZIONE
  #   Se conversation_id fornito: elimina immagini precedenti della stessa conversazione
  #   Questo garantisce che una chat abbia max 1 immagine (l'ultima sovrascrive)
  #
  # FLOW:
  #   1. Se conversation_id presente: elimina vecchie GeneratedImage records
  #   2. Crea nuovo record GeneratedImage nel DB
  #   3. Decodifica base64 → bytes binari PNG
  #   4. Attach immagine con ActiveStorage (salva su disk/S3)
  #   5. Ritorna oggetto GeneratedImage completo
  #
  # Parametri (tutti keyword):
  #   - company: Company object (per foreign key)
  #   - prompt: stringa prompt usata
  #   - image_data: stringa base64 dell'immagine
  #   - width, height, model_id, seed: metadati generazione
  #   - conversation_id: ID conversazione (optional)
  #
  # Ritorna:
  #   GeneratedImage object (salvato in DB, con file allegato)
  def save_generated_image(company:, prompt:, image_data:, width:, height:, model_id:, conversation_id:, seed:)
    # Se conversation_id fornito: elimina immagini precedenti di questa conversazione
    # dependent: :destroy su has_one_attached elimina ANCHE i file fisici (non solo record DB)
    if conversation_id.present?
      GeneratedImage.where(conversation_id: conversation_id).destroy_all
      Rails.logger.info("Immagini precedenti per conversation_id=#{conversation_id} eliminate")
    end

    # Crea nuovo record GeneratedImage nel DB
    # .create! = INSERT nel DB, solleva eccezione se fallisce
    generated_image = GeneratedImage.create!(
      company: company,  # Foreign key: azienda proprietaria
      prompt: prompt,
      conversation_id: conversation_id,  # Associa a conversazione testuale
      width: width,
      height: height,
      model_id: model_id
    )

    # Decodifica stringa base64 → bytes PNG binari
    # Base64 è formato testo per trasmettere dati binari (es: per JSON)
    # .decode64 = converte da base64 a binary
    image_bytes = Base64.decode64(image_data)
    
    # Attach file con ActiveStorage (Rails ORM per file)
    # Salvataggio: config/storage.yml determina dove
    #   - dev: file system locale (tmp/storage/)
    #   - prod: S3 AWS
    # filename: nomefile unico che include ID e seed (per debug/tracciabilità)
    #   Es: "nova_123_456789.png"
    generated_image.image.attach(
      io: StringIO.new(image_bytes),  # StringIO = stream in memoria (simula file object)
      filename: "nova_#{generated_image.id}_#{seed}.png",
      content_type: "image/png"  # MIME type PNG
    )

    generated_image  # Ritorna oggetto salvato
  end
end