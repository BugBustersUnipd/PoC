require "aws-sdk-bedrockruntime"

# AiTextGenerator - Chiamate HTTP ad Amazon Bedrock Converse API per generazione testo
#
# Questo servizio gestisce la comunicazione low-level con AWS Bedrock:
# - Inizializza client AWS SDK con credenziali
# - Invoca model_id configurato (es. anthropic.claude-3-5-sonnet-20241022-v2:0)
# - Gestisce errori AccessDenied/Throttling con fallback model
# - Estrae testo generato dalla risposta
#
# Configurazione:
# - Credenziali: ENV["AWS_ACCESS_KEY_ID"], ["AWS_SECRET_ACCESS_KEY"], ["AWS_SESSION_TOKEN"]
# - Model ID: bedrock.yml BEDROCK_CONFIG_GENERATION["model_id"]
# - Fallback: ENV["BEDROCK_FALLBACK_MODEL_ID"] per AccessDenied/Throttling
class AiTextGenerator
  # Costanti Ruby: MAIUSCOLO per valori immutabili
  # ENV key per model fallback quando primario fallisce (regione unavailable, quota, etc.)
  FALLBACK_MODEL_ENV = "BEDROCK_FALLBACK_MODEL_ID"
  
  # Region default AWS se bedrock.yml non specifica (us-east-1 ha tutti i modelli)
  REGION_DEFAULT = "us-east-1"

  # Costruttore con dependency injection
  #
  # @param client [Aws::BedrockRuntime::Client, nil] client AWS SDK (nil = crea nuovo)
  # @param region [String] regione AWS (default da bedrock.yml)
  #
  # Client injection permette:
  # - Test con mock client (niente chiamate HTTP reali)
  # - Riuso client esistente (evita overhead inizializzazione)
  #
  # Sintassi Ruby:
  #   client: nil = named parameter con default value
  #   region: ::CONST = :: accede a costante top-level namespace
  #   @variable = instance variable (visibile in tutti i metodi della classe)
  #
  # Esempio:
  #   # Produzione: usa credenziali ENV
  #   generator = AiTextGenerator.new
  #
  #   # Test: inietta mock
  #   mock_client = double("client", converse: mock_response)
  #   generator = AiTextGenerator.new(client: mock_client)
  def initialize(client: nil, region: ::BEDROCK_CONFIG_GENERATION["region"])
    @region = region
    
    # client || espressione = "usa client se fornito, altrimenti valuta espressione"
    # Aws::BedrockRuntime::Client.new = costruttore AWS SDK Ruby
    # ENV[key] accede a environment variables (variabili sistema operativo)
    @client = client || Aws::BedrockRuntime::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"],  # Optional per IAM roles
      region: @region
    )
  end

  # Genera testo chiamando Bedrock Converse API
  #
  # Converse API = interfaccia unificata Bedrock per modelli conversazionali
  # Supporta: Claude (Anthropic), Nova (Amazon), Llama (Meta), Mistral, etc.
  #
  # @param messages [Array<Hash>] messaggi formato Bedrock
  #   [{role: "user", content: [{text: "..."}]}, ...]
  # @param system_prompt [String] istruzioni sistema per l'IA
  #
  # @return [String] testo generato dal modello
  #
  # @raise [Aws::BedrockRuntime::Errors::ServiceError] errori AWS non gestiti
  #
  # Esempio:
  #   text = generator.generate_text(
  #     [{role: "user", content: [{text: "Scrivi email"}]}],
  #     "Sei assistente email professionale"
  #   )
  #   # => "Gentile cliente, benvenuto..."
  def generate_text(messages, system_prompt)
    # :: accede a costante globale caricata da bedrock.yml
    model_id = ::BEDROCK_CONFIG_GENERATION["model_id"]
    
    # Invoca Bedrock con fallback automatico per errori quota/regione
    response = invoke_bedrock_with_fallback(model_id, messages, system_prompt)

    Rails.logger.info response.inspect

    if response.stop_reason == "guardrail_intervened"
      raise Aws::BedrockRuntime::Errors::GuardrailException.new(nil, "Contenuto bloccato dai guardrails")
    end
    
    # Estrae testo da risposta Bedrock
    # response.output.message.content = array di content blocks
    # [0] = primo block (text), .text = estrae stringa
    # Struttura: {output: {message: {content: [{text: "generated text"}]}}}
    response.output.message.content[0].text
  end

  private

  # Invoca Bedrock con fallback automatico per errori specifici
  #
  # Gestisce due scenari comuni:
  # 1. AccessDeniedException: modello non disponibile in regione (es. Nova non in eu-west-1)
  # 2. ThrottlingException: quota superata per il modello (troppi requests)
  # 3. GuardrailException: contenuto bloccato dai guardrail
  #
  # Soluzione: riprova con fallback model da ENV (es. Claude invece di Nova)
  #
  # @param model_id [String] model ID primario (es. "amazon.nova-pro-v1:0")
  # @param messages [Array<Hash>] messaggi conversazione
  # @param system_prompt [String] prompt sistema
  #
  # @return [Aws::BedrockRuntime::Types::ConverseResponse] risposta Bedrock
  #
  # @raise [Aws::BedrockRuntime::Errors::ServiceError] se fallback fallisce o non configurato
  def invoke_bedrock_with_fallback(model_id, messages, system_prompt)
    # Tentativo con modello primario
    converse_with_model(model_id, messages, system_prompt)
    
  # rescue = exception handling (equivalente try/catch altri linguaggi)
  # => e = cattura eccezione nella variabile e
  # AccessDeniedException = modello non accessibile (regione, permessi)
  # ThrottlingException = rate limit superato
  rescue Aws::BedrockRuntime::Errors::AccessDeniedException, Aws::BedrockRuntime::Errors::ThrottlingException => e
    # Rails.logger.warn = log livello WARNING (non è errore critico, c'è fallback)
    # e.class = nome classe eccezione (AccessDeniedException o ThrottlingException)
    # e.message = messaggio errore da AWS
    Rails.logger.warn("Bedrock error #{e.class} for model=#{model_id} in region=#{@region}: #{e.message}")
    
    # .presence ritorna nil se stringa vuota/blank, altrimenti ritorna stringa
    # fallback = model ID alternativo da environment variable
    fallback = ENV[FALLBACK_MODEL_ENV].presence
    
    # Verifica che fallback sia configurato E diverso da modello fallito
    # && = AND logico, tutte condizioni devono essere vere
    # != = operatore diverso (not equal)
    if fallback && fallback != model_id
      Rails.logger.info("Retrying with fallback model=#{fallback}")
      # Riprova con fallback model
      converse_with_model(fallback, messages, system_prompt)
    else
      # raise = solleva eccezione originale (nessun fallback disponibile)
      # Chiamante può gestire errore (es. controller render 503)
      raise
    end
  end

  # Invoca Bedrock Converse API per un model_id specifico
  #
  # Converse è l'API unificata Bedrock per modelli conversazionali.
  # Parametri:
  # - model_id: identificatore modello (es. "anthropic.claude-3-5-sonnet-20241022-v2:0")
  # - messages: array messaggi [{role, content}]
  # - system: array istruzioni sistema [{text}]
  # - inference_config: temperature, max_tokens, top_p, etc.
  #
  # @param model_id [String] identificatore modello Bedrock
  # @param messages [Array<Hash>] messaggi conversazione
  # @param system_prompt [String] prompt sistema
  #
  # @return [Aws::BedrockRuntime::Types::ConverseResponse] risposta AWS
  #
  # Esempio risposta:
  #   {
  #     output: {
  #       message: {
  #         role: "assistant",
  #         content: [{text: "Gentile cliente..."}]
  #       }
  #     },
  #     usage: {input_tokens: 50, output_tokens: 120}
  #   }
  def converse_with_model(model_id, messages, system_prompt)
    # @client.converse = chiamata HTTP POST a Bedrock Converse API
    # Sintassi Ruby: hash come ultimo parametro non richiede {}
    @client.converse(
      model_id: model_id,
      messages: messages,
      # system deve essere array di Hash con chiave text
      # [{text: "..."}] = array con un elemento Hash
      system: [{ text: system_prompt }],
      # inference_config = parametri generazione (temperature, tokens, etc.)
      inference_config: bedrock_inference_config,
      guardrail_config: {
        guardrail_identifier: "gs9kmq0fkkzj",
        guardrail_version: "2"
      }
    )
  end

  # Costruisce configurazione inference per Bedrock
  #
  # Parametri generazione AI:
  # - max_tokens: massimo token risposta (es. 2000 = ~1500 parole)
  # - temperature: randomness 0.0-1.0 (0.7 = bilanciato creatività/coerenza)
  #
  # Temperature:
  # - 0.0-0.3: deterministico, coerente (codice, documentazione)
  # - 0.4-0.7: bilanciato (uso generale)
  # - 0.8-1.0: creativo, vario (brainstorming, storytelling)
  #
  # @return [Hash] configurazione inference
  #
  # Esempio:
  #   {max_tokens: 2000, temperature: 0.7}
  def bedrock_inference_config
    # Hash con chiavi Symbol (:max_tokens) per prestazioni
    # :: accede a costanti globali da bedrock.yml
    {
      max_tokens: ::BEDROCK_CONFIG_GENERATION["max_tokens"],
      temperature: ::BEDROCK_CONFIG_GENERATION["temperature"]
    }
  end
end