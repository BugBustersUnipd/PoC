require "base64"

# ImageStorage - Persistenza immagini generate: DB + ActiveStorage
#
# Questo servizio gestisce il salvataggio completo di immagini generate:
# 1. Elimina immagini precedenti della stessa conversazione (1 img per conv)
# 2. Crea record GeneratedImage nel database (metadati)
# 3. Decodifica base64 → bytes PNG
# 4. Salva file su disco con ActiveStorage (blob + attachment)
#
# ActiveStorage = sistema Rails per gestione file:
# - Salva file su disco locale (development) o cloud (S3, Azure, GCS)
# - Genera URL firmati temporanei per accesso sicuro
# - Gestisce metadati (filename, content_type, byte_size, checksum)
# - Integra con modelli via has_one_attached/has_many_attached
#
# Pattern: Repository per persistenza file + metadati
class ImageStorage
  # Salva immagine generata: record DB + file ActiveStorage
  #
  # Politica: 1 sola immagine per conversazione
  # - Se conversation_id presente: elimina immagini precedenti prima di salvare
  # - Motivo: UI mostra solo ultima immagine, conservare vecchie spreca storage
  #
  # @param company [Company] azienda proprietaria (ownership)
  # @param prompt [String] prompt usato per generare immagine (audit/riproduzione)
  # @param image_data [String] immagine PNG codificata base64
  # @param width [Integer] larghezza immagine in pixel
  # @param height [Integer] altezza immagine in pixel
  # @param model_id [String] model ID Bedrock usato (es. "amazon.nova-canvas-v1:0")
  # @param conversation_id [Integer, nil] ID conversazione associata (optional)
  # @param seed [Integer] seed usato per generazione (riproducibilità)
  #
  # @return [GeneratedImage] record salvato con file attached
  #
  # Esempio:
  #   img_record = storage.save(
  #     company,
  #     "Logo startup tech",
  #     "iVBORw0KGgo...",  # base64 string
  #     1024, 1024,
  #     "amazon.nova-canvas-v1:0",
  #     123,  # conversation_id
  #     42    # seed
  #   )
  #   # => #<GeneratedImage id: 456, image: attached>
  def save(company, prompt, image_data, width, height, model_id, conversation_id, seed)
    # Elimina immagini precedenti per questa conversazione (se presente)
    # .present? = true se valore non è nil/empty
    if conversation_id.present?
      # .where query SQL: SELECT * FROM generated_images WHERE conversation_id = ?
      # .destroy_all elimina tutti record trovati (trigger callbacks + elimina file ActiveStorage)
      # Alternativa .delete_all è più veloce ma non triggera callbacks
      GeneratedImage.where(conversation_id: conversation_id).destroy_all
      
      # Log per audit trail (chi ha eliminato cosa e quando)
      Rails.logger.info("Immagini precedenti per conversation_id=#{conversation_id} eliminate")
    end

    # Crea record GeneratedImage nel database
    # create! = crea e salva immediatamente (lancia eccezione se validazioni falliscono)
    # ! suffix = bang method, solleva ActiveRecord::RecordInvalid se errori
    generated_image = GeneratedImage.create!(
      company: company,  # Associazione belongs_to (foreign key company_id)
      prompt: prompt,
      conversation_id: conversation_id,
      width: width,
      height: height,
      model_id: model_id
      # created_at, updated_at gestiti automaticamente da ActiveRecord
    )

    # Decodifica base64 → bytes binary PNG
    # Base64 = encoding per rappresentare dati binari come testo ASCII
    # Bedrock ritorna immagine PNG come stringa base64 (trasporto JSON sicuro)
    # Base64.decode64 = converte stringa base64 in bytes originali
    #
    # Esempio:
    #   Base64.decode64("iVBORw0K...") # => "\x89PNG\r\n..." (binary data)
    image_bytes = Base64.decode64(image_data)

    # Attach file con ActiveStorage
    # generated_image.image = accessor definito da has_one_attached :image nel model
    # .attach = metodo ActiveStorage per associare file a record
    generated_image.image.attach(
      # io: oggetto IO-like (deve rispondere a read, rewind, size)
      # StringIO = wrapper Ruby per trattare stringa come file IO
      # StringIO.new(bytes) crea "file virtuale" in memoria (niente disco temporaneo)
      io: StringIO.new(image_bytes),
      
      # filename per storage (visibile in URL signed e download)
      # Formato: nova_<id>_<seed>.png
      # - generated_image.id = ID record appena creato
      # - seed = per identificare generazioni con stesso prompt
      filename: "nova_#{generated_image.id}_#{seed}.png",
      
      # content_type = MIME type per HTTP headers
      # Importante per browser: determina come visualizzare file
      content_type: "image/png"
    )

    # Ritorna record GeneratedImage con file attached
    # A questo punto:
    # - Record salvato in DB (generated_images table)
    # - File salvato su disco (storage/ directory in dev, S3/etc in prod)
    # - ActiveStorage ha creato 2 record: active_storage_blobs + active_storage_attachments
    generated_image
  end
end