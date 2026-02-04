# GeneratedImageSerializer - Formattazione JSON per risposte API generazione immagini
#
# Trasforma dati interni (GeneratedImage model + metadati) in formato JSON
# consistente per frontend.

class GeneratedImageSerializer
  # Serializza risposta generazione immagine
  #
  # Metodo di classe (self.method_name):
  # - self. = metodo chiamato su classe, non su istanza
  # - Chiamata: GeneratedImageSerializer.serialize(...)
  #
  # @param generated_image [GeneratedImage] record DB salvato
  # @param image_url [String] URL firmato ActiveStorage (rails_blob_path)
  # @param width [Integer] larghezza immagine
  # @param height [Integer] altezza immagine
  # @param model_id [String] model ID Bedrock usato
  #
  # @return [Hash] JSON structure pronto per render json:
  #
  # Esempio:
  #   GeneratedImageSerializer.serialize(
  #     generated_image: img_record,
  #     image_url: "https://app.com/rails/active_storage/blobs/.../image.png",
  #     width: 1024,
  #     height: 1024,
  #     model_id: "amazon.nova-canvas-v1:0"
  #   )
  #   # => {
  #   #   image_url: "https://...",
  #   #   image_id: 123,
  #   #   width: 1024,
  #   #   height: 1024,
  #   #   model_id: "amazon.nova-canvas-v1:0",
  #   #   created_at: "2024-01-15T10:30:00Z"
  #   # }
  def self.serialize(generated_image:, image_url:, width:, height:, model_id:)
    {
      image_url: image_url,  # URL pubblico firmato per browser
      image_id: generated_image.id,  # ID record per tracking/eliminazione
      width: width,
      height: height,
      model_id: model_id,  # Quale modello AI ha generato (audit)
      
      # .iso8601 = formato timestamp ISO 8601: "2024-01-15T10:30:00Z"
      # Standard internazionale per date in JSON/API
      # Vantaggi: timezone-aware (Z = UTC), parsing universale JavaScript/Python
      created_at: generated_image.created_at.iso8601
    }
  end
end
