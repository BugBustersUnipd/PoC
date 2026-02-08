require "aws-sdk-bedrockruntime"
require "json"

# ImageGenerator - Chiamate HTTP ad Amazon Bedrock Nova Canvas per generazione immagini
#
# Questo servizio gestisce la comunicazione low-level con Nova Canvas:
# - Inizializza client AWS SDK con credenziali
# - Costruisce payload JSON specifico per Nova Canvas (taskType, textToImageParams, etc.)
# - Invoca invoke_model API (diverso da Converse, usato per immagini)
# - Estrae immagine base64 dalla risposta JSON
#
# Differenze con AiTextGenerator:
# - API: invoke_model (JSON payload custom) vs converse (schema standard)
# - Response: JSON con immagine base64 vs text strutturato
# - Configurazione: dimensioni fisse (1024x1024, etc.) vs token budget
#
# - Isola complessità payload JSON specifico Nova
# - Gestisce parsing risposta con chiavi multiple possibili ("images", "image", etc.)
# - Fornisce interfaccia semplice generate(prompt, width, height, seed)
class ImageGenerator
  # Costruttore con dependency injection
  # Comportamento identico ad AiTextGenerator, client iniettabile per testing.

  def initialize(client: nil, region: ::BEDROCK_CONFIG_IMAGE_GENERATION["region"])
    @region = region
    @client = client || Aws::BedrockRuntime::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"],
      region: @region
    )
  end

  # Genera immagine chiamando Nova Canvas
  #
  # Nova Canvas = modello Amazon per text-to-image
  # Supporta dimensioni: 1024x1024, 1280x720, 720x1280
  # Non supporta: dimensioni arbitrarie, upscaling, inpainting
  def generate(prompt, width, height, seed)
    model_id = ::BEDROCK_CONFIG_IMAGE_GENERATION["model_id"]
    
    # Costruisce JSON payload specifico per Nova Canvas
    body = build_nova_payload(prompt, width, height, seed)

    # Log per debug/monitoring (timestamp automatico da Rails.logger)
    Rails.logger.info("NovaCanvas: Generazione [#{width}x#{height}] Seed: #{seed}")

    # Chiamata HTTP POST a Bedrock invoke_model
    response = invoke_bedrock(model_id, body)
    
    # Estrae base64 da JSON risposta
    extract_image_data(response)
  end

  private

  # Costruisce payload JSON per Nova Canvas API
  #
  # Struttura richiesta da Nova Canvas:
  # {
  #   taskType: "TEXT_IMAGE",  # Tipo task (TEXT_IMAGE, IMAGE_VARIATION, etc.)
  #   textToImageParams: {     # Parametri generazione da testo
  #     text: "prompt",
  #     negativeText: "cosa evitare"  # Quality filters
  #   },
  #   imageGenerationConfig: { # Configurazione tecnica
  #     numberOfImages: 1,
  #     height: 1024,
  #     width: 1024,
  #     cfgScale: 7.0,        # Classifier-Free Guidance (quanto seguire prompt)
  #     seed: 12345
  #   }
  # }
  # Sintassi Ruby:
  #   {key: value} = Hash con Symbol keys (più veloce di String keys)
  #   .to_json = converte Hash Ruby in stringa JSON (metodo da json gem)
  def build_nova_payload(prompt, width, height, seed)
    # Hash Ruby che verrà convertito in JSON
    {
      # Symbol keys vengono serializzate come string keys in JSON
      taskType: "TEXT_IMAGE",
      textToImageParams: {
        text: prompt,
        # negativeText = prompt negativo per filtrare elementi indesiderati
        # Lista comune: low quality, watermark, text, blur, distorted
        negativeText: "low quality, bad anatomy, distorted, watermark, text, signature, blur, grainy"
      },
      imageGenerationConfig: {
        numberOfImages: 1,  # Nova supporta max 5, ma usiamo 1 per costi
        height: height,
        width: width,
        # cfgScale (Classifier-Free Guidance): quanto aderire al prompt
        # 1.0 = ignora prompt (casuale), 20.0 = segui letteralmente
        # 7.0 = compromesso qualità/creatività (valore raccomandato AWS)
        cfgScale: 7.0,
        seed: seed
      }
    }.to_json  # Converte Hash in JSON string
  end

  # Invoca Bedrock invoke_model API
  #
  # invoke_model = API generica Bedrock per modelli custom/non-Converse
  # Richiede payload JSON specifico per ogni modello (Nova, Stable Diffusion, etc.)
  #
  # @param model_id [String] identificatore modello (es. "amazon.nova-canvas-v1:0")
  # @param body [String] JSON payload costruito da build_nova_payload
  #
  # @return [Aws::BedrockRuntime::Types::InvokeModelResponse] risposta AWS
  #   response.body = StringIO contenente JSON risposta
  #
  # @raise [Aws::BedrockRuntime::Errors::ValidationException] parametri invalidi
  # @raise [Aws::BedrockRuntime::Errors::ServiceError] altri errori AWS
  #
  # Gestione errori:
  # - ValidationException: dimensioni non supportate, seed out of range
  # - ServiceError: quota superata, regione unavailable, etc.
  def invoke_bedrock(model_id, body)
    # @client.invoke_model = chiamata HTTP POST sincrona
    # Timeout default: 60 secondi (generazione immagine lenta ~10-30 sec)
    @client.invoke_model(
      model_id: model_id,
      body: body,  # JSON string da build_nova_payload
      content_type: "application/json",  # Header Content-Type
      accept: "application/json"          # Header Accept
    )
    
  # rescue ValidationException = cattura solo questo tipo eccezione
  # => e = salva eccezione in variabile e
  rescue Aws::BedrockRuntime::Errors::ValidationException => e
    # ValidationException = parametri request invalidi (400 Bad Request)
    # Cause comuni: dimensioni non supportate (es. 800x600), seed < 0, etc.
    Rails.logger.error("Errore validazione parametri Nova: #{e.message}")
    
    # raise ArgumentError = solleva eccezione diversa per controller
    # ArgumentError è Ruby standard, più semantico di AWS error specifico
    raise ArgumentError, "Parametri non validi per il modello (controlla dimensioni/seed)"
    
  # rescue ServiceError = cattura tutti altri errori AWS (500, 503, etc.)
  rescue Aws::BedrockRuntime::Errors::ServiceError => e
    Rails.logger.error("Bedrock API Error: #{e.code} - #{e.message}")
    # raise = rilancia eccezione originale senza modifiche
    raise
  end

  # Estrae immagine base64 da risposta JSON Nova Canvas
  #
  # Problema: Nova Canvas ha cambiato struttura risposta tra versioni
  # Possibili chiavi JSON:
  # - {"images": ["base64..."]}           # Array di immagini (v1)
  # - {"image": "base64..."}              # Singola immagine (v2)
  # - {"image_base64": "base64..."}       # Alternativa (documentazione)
  # - {"imageUriBase64": "base64..."}     # Altra variante osservata
  #
  # Soluzione: prova tutte le chiavi possibili in ordine
  #
  # @param response [Aws::BedrockRuntime::Types::InvokeModelResponse] risposta invoke_model
  #
  # @return [String] immagine PNG codificata base64
  #
  # @raise [RuntimeError] se nessuna chiave contiene immagine
  def extract_image_data(response)
    # response.body = StringIO (oggetto simile a file)
    # .read = legge tutto contenuto come stringa
    # JSON.parse = converte JSON string in Hash Ruby
    payload = JSON.parse(response.body.read)

    # Log chiavi presenti per debug (utile se Nova cambia formato ancora)
    # payload.keys = array chiavi Hash
    # .join(', ') = unisce array in stringa separata da virgole
    Rails.logger.info("Nova Canvas Response keys: #{payload.keys.join(', ')}")

    # Prova chiave "images" (array di stringhe base64)
    # &. = safe navigation operator (evita errore se payload["images"] è nil)
    # .any? = true se array ha almeno un elemento
    if payload["images"]&.any?
      # .first = primo elemento array
      payload["images"].first
      
    # Prova chiave "image" (singola stringa base64)
    elsif payload["image"]
      payload["image"]
      
    # Prova chiave "image_base64"
    elsif payload["image_base64"]
      payload["image_base64"]
      
    # Prova chiave "imageUriBase64"
    elsif payload["imageUriBase64"]
      payload["imageUriBase64"]
      
    # Nessuna chiave trovata: errore
    else
      # .inspect = rappresentazione debug dell'oggetto (mostra tutta struttura)
      Rails.logger.error("Nova Canvas: Response non contenente immagine. Payload completo: #{payload.inspect}")
      
      # raise String = solleva RuntimeError con messaggio
      # Include chiavi presenti per facilitare debug
      raise "Errore Nova Canvas: Nessuna immagine ritornata. Payload keys: #{payload.keys.join(', ')}"
    end
  end
end