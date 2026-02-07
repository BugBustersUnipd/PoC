# Serializza immagine generata da Bedrock
class GeneratedImageSerializer
  # Ritorna URL immagine + metadati (dimensioni, model_id, timestamp)
  def self.serialize(generated_image:, image_url:, width:, height:, model_id:)
    {
      image_url: image_url,                           # URL ActiveStorage firmato
      image_id: generated_image.id,
      width: width,
      height: height,
      model_id: model_id,                             # es: "amazon.nova-canvas-v1:0"
      created_at: generated_image.created_at.iso8601
    }
  end
end
