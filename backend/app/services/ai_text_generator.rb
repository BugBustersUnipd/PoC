require "aws-sdk-bedrockruntime"

class AiTextGenerator
  FALLBACK_MODEL_ENV = "BEDROCK_FALLBACK_MODEL_ID"
  REGION_DEFAULT = "us-east-1"

  def initialize
    @region = ::BEDROCK_CONFIG_GENERATION["region"]
    @client = Aws::BedrockRuntime::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"],
      region: @region
    )
  end

  def generate_text(messages, system_prompt)
    model_id = ::BEDROCK_CONFIG_GENERATION["model_id"]
    response = invoke_bedrock_with_fallback(model_id, messages, system_prompt)
    response.output.message.content[0].text
  end

  private

  def invoke_bedrock_with_fallback(model_id, messages, system_prompt)
    converse_with_model(model_id, messages, system_prompt)
  rescue Aws::BedrockRuntime::Errors::AccessDeniedException, Aws::BedrockRuntime::Errors::ThrottlingException => e
    Rails.logger.warn("Bedrock error #{e.class} for model=#{model_id} in region=#{@region}: #{e.message}")
    fallback = ENV[FALLBACK_MODEL_ENV].presence
    if fallback && fallback != model_id
      Rails.logger.info("Retrying with fallback model=#{fallback}")
      converse_with_model(fallback, messages, system_prompt)
    else
      raise
    end
  end

  def converse_with_model(model_id, messages, system_prompt)
    @client.converse(
      model_id: model_id,
      messages: messages,
      system: [{ text: system_prompt }],
      inference_config: bedrock_inference_config
    )
  end

  def bedrock_inference_config
    {
      max_tokens: ::BEDROCK_CONFIG_GENERATION["max_tokens"],
      temperature: ::BEDROCK_CONFIG_GENERATION["temperature"]
    }
  end
end