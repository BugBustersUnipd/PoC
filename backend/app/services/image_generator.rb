require "aws-sdk-bedrockruntime"
require "json"

class ImageGenerator
  def initialize
    @region = ::BEDROCK_CONFIG_IMAGE_GENERATION["region"]
    @client = Aws::BedrockRuntime::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"],
      region: @region
    )
  end

  def generate(prompt, width, height, seed)
    model_id = ::BEDROCK_CONFIG_IMAGE_GENERATION["model_id"]
    body = build_nova_payload(prompt, width, height, seed)

    Rails.logger.info("NovaCanvas: Generazione [#{width}x#{height}] Seed: #{seed}")

    response = invoke_bedrock(model_id, body)
    extract_image_data(response)
  end

  private

  def build_nova_payload(prompt, width, height, seed)
    {
      taskType: "TEXT_IMAGE",
      textToImageParams: {
        text: prompt,
        negativeText: "low quality, bad anatomy, distorted, watermark, text, signature, blur, grainy"
      },
      imageGenerationConfig: {
        numberOfImages: 1,
        height: height,
        width: width,
        cfgScale: 7.0,
        seed: seed
      }
    }.to_json
  end

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

  def extract_image_data(response)
    payload = JSON.parse(response.body.read)

    Rails.logger.info("Nova Canvas Response keys: #{payload.keys.join(', ')}")

    if payload["images"]&.any?
      payload["images"].first
    elsif payload["image"]
      payload["image"]
    elsif payload["image_base64"]
      payload["image_base64"]
    elsif payload["imageUriBase64"]
      payload["imageUriBase64"]
    else
      Rails.logger.error("Nova Canvas: Response non contenente immagine. Payload completo: #{payload.inspect}")
      raise "Errore Nova Canvas: Nessuna immagine ritornata. Payload keys: #{payload.keys.join(', ')}"
    end
  end
end