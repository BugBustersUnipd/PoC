require "aws-sdk-bedrockruntime"
require "json"
require "base64"

# ImageService - Servizio orchestratore per generazione immagini via Amazon Bedrock Nova Canvas
#
# Questo servizio coordina l'intero flusso di generazione immagini:
# 1. Valida che dimensioni richieste siano supportate (1024x1024, 1280x720, 720x1280)
# 2. Recupera azienda e configurazione modello
# 3. Genera seed casuale se non fornito (per riproducibilità)
# 4. Chiama API Bedrock Nova Canvas per generare immagine
# 5. Elimina eventuali immagini precedenti della stessa conversazione (1 img per conv)
# 6. Salva immagine nel DB (GeneratedImage) + storage (ActiveStorage)
#
# Pattern utilizzato: Service Orchestrator
# - Delega validazione, generazione, storage a componenti specializzati
# - Ogni componente ha una singola ragione per cambiare (SRP)
#
# Dipendenze iniettate:
# @param image_validator [ImageValidator] valida dimensioni supportate
# @param image_generator [ImageGenerator] chiamate HTTP a Bedrock
# @param image_storage [ImageStorage] persistenza DB + ActiveStorage
class ImageService
  def initialize(image_validator:, image_generator:, image_storage:)
    @image_validator = image_validator
    @image_generator = image_generator
    @image_storage = image_storage
  end

  # Genera un'immagine usando Amazon Bedrock Nova Canvas
  #
  # Nova Canvas supporta solo dimensioni specifiche per aspect ratio ottimali.
  # Se conversation_id è fornito, elimina automaticamente immagini precedenti
  # (politica: 1 sola immagine per conversazione, l'ultima sovrascrive).
  #
  # @param prompt [String] descrizione immagine da generare (es. "Logo aziendale moderno")
  # @param company_id [Integer] ID azienda per ownership e tracciamento
  # @param conversation_id [Integer, nil] ID conversazione testuale da associare (optional)
  # @param width [Integer] larghezza in pixel (default 1024, valori: 1024, 1280, 720)
  # @param height [Integer] altezza in pixel (default 1024, valori: 1024, 720, 1280)
  # @param seed [Integer, nil] seed per riproducibilità (nil = casuale)
  #
  # @return [Hash] {
  #   generated_image_object: GeneratedImage,  # Record DB salvato
  #   width: 1024, height: 1024,              # Dimensioni confermate
  #   seed: 12345,                             # Seed usato (generato se nil)
  #   model_id: "amazon.nova-canvas-v1:0"     # Modello Bedrock
  # }
  #
  # @raise [ArgumentError] se dimensioni non supportate (es. 800x600)
  # @raise [ActiveRecord::RecordNotFound] se company_id non esiste
  #
  # Esempio:
  #   result = image_service.genera(
  #     prompt: "Logo minimalista per startup tech",
  #     company_id: 1,
  #     width: 1024,
  #     height: 1024,
  #     seed: 42  # Stesso seed = stessa immagine
  #   )
  def genera(prompt:, company_id:, conversation_id: nil, width: 1024, height: 1024, seed: nil)
    # Valida dimensioni PRIMA di chiamare API (fail-fast)
    # Solleva ArgumentError se combinazione width/height non supportata
    @image_validator.validate_size!(width, height)

    # find lancia eccezione se company_id non esiste
    company = Company.find(company_id)
    
    # :: prefisso accede a costante globale (top-level namespace)
    # BEDROCK_CONFIG_IMAGE_GENERATION è caricato da config/bedrock.yml all'avvio Rails
    model_id = ::BEDROCK_CONFIG_IMAGE_GENERATION["model_id"]

    # Nova Canvas accetta seed tra 0 e 2_147_483_647 (max signed int32)
    # seed = riproducibilità: stesso seed + stesso prompt = stessa immagine generata
    # Utile per: test deterministici, rigenerare esatta immagine, debug
    # _ in numeri è separator per leggibilità (2_147_483_647 == 2147483647)
    actual_seed = seed.present? ? seed.to_i : rand(0..2_147_483_647)

    # Chiamata API Bedrock Nova Canvas
    # Ritorna stringa base64 dell'immagine PNG generata
    image_data = @image_generator.generate(prompt, width, height, actual_seed)

    # Salva nel DB (GeneratedImage record) + disco (ActiveStorage blob)
    # Gestisce anche eliminazione immagini precedenti se conversation_id presente
    generated_image = @image_storage.save(
      company, prompt, image_data, width, height, model_id, conversation_id, actual_seed
    )

    # Ritorna metadati per il controller
    # image_url verrà generato dal controller con rails_blob_path (URL firmato)
    {
      image_url: nil, # Controller genererà URL pubblico firmato
      generated_image_object: generated_image,
      width: width,
      height: height,
      seed: actual_seed,
      model_id: model_id
    }
  end
end
