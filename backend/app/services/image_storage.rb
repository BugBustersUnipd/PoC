require "base64"

class ImageStorage
  def save(company, prompt, image_data, width, height, model_id, conversation_id, seed)
    # Elimina immagini precedenti per questa conversazione
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
    generated_image.image.attach(
      io: StringIO.new(image_bytes),
      filename: "nova_#{generated_image.id}_#{seed}.png",
      content_type: "image/png"
    )

    generated_image
  end
end