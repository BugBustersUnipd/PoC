require "aws-sdk-bedrockruntime"
require "json"
require "base64"

# ImageService
# - Servizio per generare immagini usando Amazon Bedrock Nova Canvas
# - Gestisce il ciclo completo: validazione, chiamata API, salvataggio con ActiveStorage
# - Elimina automaticamente immagini precedenti della stessa conversazione (1 sola immagine per conversazione)
# - Configurazione caricata da bedrock.yml via BEDROCK_CONFIG_IMAGE_GENERATION
class ImageService
  def initialize
    @generator = ImageGenerator.new
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
    ImageValidator.validate_size!(width, height)

    company = Company.find(company_id)
    model_id = ::BEDROCK_CONFIG_IMAGE_GENERATION["model_id"]

    # Nova gestisce i seed tra 0 e 2147483647 (max signed int32)
    # Seed = riproducibilità: stesso seed + stesso prompt = stessa immagine
    actual_seed = seed.present? ? seed.to_i : rand(0..2_147_483_647)

    # Genera l'immagine
    image_data = @generator.generate(prompt, width, height, actual_seed)

    # Salva nel DB e su disco
    generated_image = ImageStorage.save(
      company, prompt, image_data, width, height, model_id, conversation_id, actual_seed
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
end
