require "aws-sdk-bedrockruntime"
require "json"

class DocumentAnalysisService
  BEDROCK_CONFIG = ::BEDROCK_CONFIG_ANALYSIS  # Profilo specifico per analisi

  # Formati supportati (MIME type)
  SUPPORTED_FORMATS = BEDROCK_CONFIG["supported_formats"].freeze

  # Analizza un documento e ne estrae i dati via Bedrock
  # @param document [Document] il documento da analizzare
  # @return [Hash] dati estratti { tipo_documento, data_competenza, codice_fiscale, dipendente }
  # @raise [DocumentAnalysisError] se il file non è supportato o Bedrock fallisce
  def self.analyze(document)
    new.analyze(document)
  end

  def analyze(document)
    raise DocumentAnalysisError, "File non allegato" unless document.original_file.attached?

    # Estrai contenuto e MIME type
    file_content = document.original_file.download
    mime_type = document.original_file.content_type

    # Valida formato
    raise DocumentAnalysisError, "Formato non supportato: #{mime_type}" unless SUPPORTED_FORMATS.include?(mime_type)

    # Prepara blocco media (PDF vs immagini)
    media_block = build_media_block(file_content, mime_type)

    # Chiama Bedrock
    response = call_bedrock([ media_block, prompt_block ])

    # Estrae e parsa il JSON dalla risposta
    extract_json_from_response(response)
  end

  private

  def build_media_block(file_content, mime_type)
    case mime_type
    when "application/pdf"
      {
        document: {
          name: "document",
          format: "pdf",
          source: { bytes: file_content }
        }
      }
    when /^image\//
      # Normalizza il formato immagine
      format = mime_type.split("/").last
      format = "jpeg" if format == "jpg"

      {
        image: {
          format: format,
          source: { bytes: file_content }
        }
      }
    else
      raise DocumentAnalysisError, "MIME type non gestito: #{mime_type}"
    end
  end

  def prompt_block
    {
      text: <<~PROMPT.strip
        Analizza questo documento/immagine e estrai i seguenti dati in formato JSON valido:
        - tipo_documento: tipo di documento (es. Cedolino, CUD, Fattura, Ricevuta, Bilancio, Lettera HR, Contratto, Verbale, ecc.)
        - redattore: nome completo del dipendente (se applicabile)
        - mittente: chi ha inviato il documento
        - destinatario: a chi è indirizzato il documento
        - data_emissione: data di emissione del documento
        - data_competenza: data di competenza o emissione
        - numero_documento: numero identificativo del documento (es. numero fattura, protocollo)
        - versione_documento: versione o revisione del documento (se presente)
        - oggetto: oggetto o titolo del documento
        - categoria: categoria generale (es. Finanziario, HR, Legale, Amministrativo)
        - dipendente: nome completo del dipendente (se applicabile)
        - codice_fiscale: codice fiscale del dipendente (se presente)
        - azienda_riferimento: nome dell'azienda coinvolta o di riferimento (non quella del mittente, non deve esserci sempre)
        - importo_totale: importo totale o valore economico (se presente, come numero)
        - riassunto: breve riassunto del contenuto principale (max 200 caratteri)
        - numero_pagine: numero totale di pagine del documento

        Rispondi SOLO con il JSON, senza testo aggiuntivo.
        Se un campo non è presente o non applicabile, usa null.
      PROMPT
    }
  end

  def call_bedrock(content_blocks)
    client = Aws::BedrockRuntime::Client.new(
      region: BEDROCK_CONFIG["region"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"]
    )

    client.converse(
      model_id: BEDROCK_CONFIG["model_id"],
      messages: [
        {
          role: "user",
          content: content_blocks
        }
      ],
      inference_config: {
        temperature: BEDROCK_CONFIG["temperature"],
        max_tokens: BEDROCK_CONFIG["max_tokens"]
      }#,
      # guardrail_config: {
      #   guardrail_identifier: "gs9kmq0fkkzj",
      #   guardrail_version: "2"
      # }
    )
  rescue Aws::BedrockRuntime::Errors::ServiceError => e
    raise DocumentAnalysisError, "Bedrock error: #{e.message}"
  rescue StandardError => e
    raise DocumentAnalysisError, "API error: #{e.message}"
  end

  def extract_json_from_response(response)
    text = response.output.message.content.first.text

    # Estrae il primo blocco JSON trovato (più robusto di semplice regex)
    json_match = text.match(/\{[\s\S]*\}/)
    raise DocumentAnalysisError, "Nessun JSON trovato nella risposta" unless json_match

    parsed = JSON.parse(json_match[0])
    validate_json_structure(parsed)
    parsed
  rescue JSON::ParsingError => e
    raise DocumentAnalysisError, "JSON parsing error: #{e.message}"
  end

  def validate_json_structure(parsed)
    # Non richiediamo che tutti i campi siano presenti, solo che la struttura sia una hash
    raise DocumentAnalysisError, "Risposta non è un JSON object" unless parsed.is_a?(Hash)
  end
end

class DocumentAnalysisError < StandardError; end
