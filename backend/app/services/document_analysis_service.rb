require "aws-sdk-bedrockruntime"
require "json"

# DocumentAnalysisService: analisi documenti (PDF, immagini) con Bedrock IA
#
# Usa Bedrock per estrarre dati strutturati da documenti caricati:
#   - Riconosce tipo documento (cedolino, fattura, contratto, ecc.)
#   - Estrae dati rilevanti (date, nomi, importi, codici fiscali, ecc.)
#   - Ritorna tutto in formato JSON strutturato
#
# FLOW TIPICO:
#   1. AnalyzeDocumentJob.perform(doc_id) carica documento
#   2. DocumentAnalysisService.analyze(doc) esegue analisi Bedrock
#   3. Bedrock Vision API riconosce contenuto del documento
#   4. Parser estrae JSON strutturato
#   5. Job salva risultati in document.ai_data
#   6. Frontend mostra dati estratti all'utente
#
# FORMATI SUPPORTATI: PDF, PNG, JPG, GIF, WEBP (definito in bedrock.yml)
class DocumentAnalysisService
  # Profilo specifico per document analysis (diverso da generation profile)
  # Include: region, model_id (es: claude-3-5-sonnet), max_tokens, temperature
  BEDROCK_CONFIG = ::BEDROCK_CONFIG_ANALYSIS

  # Formati MIME type supportati (caricato da config e congelato)
  # .freeze = immutabile (prevent accidental modification in memory)
  # Es: ["application/pdf", "image/png", "image/jpeg"]
  SUPPORTED_FORMATS = BEDROCK_CONFIG["supported_formats"].freeze

  # Analizza un documento e ne estrae i dati via Bedrock
  # 
  # @param document [Document] il documento da analizzare
  # @return [Hash] dati estratti { tipo_documento, data_competenza, codice_fiscale, ... }
  # @raise [DocumentAnalysisError] se il file non è supportato o Bedrock fallisce
  #
  # NOTA: Questo è un "factory method" - crea istanza e chiama metodo
  # Permette di usare: DocumentAnalysisService.analyze(doc) (class method)
  # Internamente: DocumentAnalysisService.new.analyze(doc) (instance method)
  # Benefit: interface più pulita, caching possibile in futuro
  def self.analyze(document)
    new.analyze(document)
  end

  # Metodo principale: esegue analisi del documento
  def analyze(document)
    # Validazione: il file deve essere allegato (present in ActiveStorage)
    raise DocumentAnalysisError, "File non allegato" unless document.original_file.attached?

    # Scarica contenuto file dal storage (disk/S3 → memory come binary)
    # .download = file_content è stringa di bytes
    file_content = document.original_file.download
    
    # Legge MIME type del file (es: "application/pdf", "image/png")
    # Salvato da ActiveStorage quando il file fu caricato
    mime_type = document.original_file.content_type

    # Valida che il formato sia supportato
    # Se non supportato, solleva errore PRIMA di mandare a Bedrock (fail-fast)
    raise DocumentAnalysisError, "Formato non supportato: #{mime_type}" unless SUPPORTED_FORMATS.include?(mime_type)

    # Prepara blocco media nel formato richiesto da Bedrock
    # Bedrock richiede formati diversi per PDF vs immagini
    media_block = build_media_block(file_content, mime_type)

    # Invoca Bedrock con media block + prompt di estrazione
    # Bedrock torna una risposta con dati estratti (idealmente JSON)
    response = call_bedrock([ media_block, prompt_block ])

    # Estrae il JSON dalla risposta (Bedrock può tornare testo + JSON)
    # Parser robusto che cerca il primo blocco JSON (evita errori se testo aggiuntivo)
    extract_json_from_response(response)
  end

  private

  # Costruisce il "content block" media nel formato richiesto da Bedrock Converse API
  # 
  # Bedrock richiede formati diversi per:
  #   - PDF: { document: { format: "pdf", source: { bytes: ... } } }
  #   - Immagini: { image: { format: "png", source: { bytes: ... } } }
  #
  # Perché? Bedrock ottimizza processingnel modo diverso per tipi di file
  def build_media_block(file_content, mime_type)
    case mime_type
    when "application/pdf"
      # PDF: usa blocco "document" con format: "pdf"
      {
        document: {
          name: "document",        # Nome descrittivo (non usato per processing)
          format: "pdf",           # Specifica formato PDF
          source: { bytes: file_content }  # Binary content del PDF
        }
      }
    when /^image\//
      # Regex match per image/* (image/png, image/jpeg, ecc.)
      # Estrae il tipo immagine dopo il "/" (png, jpeg, gif, ecc.)
      format = mime_type.split("/").last
      
      # Normalizza: JPEG ha alias "jpg" vs "jpeg"
      # Bedrock accetta "jpeg" non "jpg"
      format = "jpeg" if format == "jpg"

      {
        image: {
          format: format,  # png, jpeg, gif, webp
          source: { bytes: file_content }
        }
      }
    else
      # MIME type non gestito (dovrebbe essere coperto da validazione supported_formats)
      # Ma se passa, lanciamo errore descrittivo
      raise DocumentAnalysisError, "MIME type non gestito: #{mime_type}"
    end
  end

  # Costruisce il prompt per Bedrock (istruzioni di estrazione)
  # 
  # Ritorna un "content block" di tipo testo che istruisce Bedrock:
  #   "Analizza questo documento e estrai questi campi in JSON"
  #
  # Formato: { text: "..." } (richiesto da Bedrock Converse API)
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

  # Invoca l'API Bedrock Converse per analizzare documento
  # 
  # Parametri:
  #   - content_blocks: array con [media_block, prompt_block] caricati insieme
  #
  # Formato richiesta: Converse API (multi-turn conversations con media support)
  # - messages: [{ role: "user", content: [media_block, prompt_block] }]
  # - model_id: ID modello Vision (es: "claude-3-5-sonnet-v1")
  # - inference_config: temperature, max_tokens
  def call_bedrock(content_blocks)
    # Crea client Bedrock con credenziali AWS da ENV
    client = Aws::BedrockRuntime::Client.new(
      region: BEDROCK_CONFIG["region"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"]
    )

    # Invoca converse (multi-turn conversation API)
    # Nota: per questo use case non usiamo conversazioni multi-turn
    # (solo 1 messaggio user), ma Converse è la API che supporta media (immagini/PDF)
    client.converse(
      model_id: BEDROCK_CONFIG["model_id"],  # Es: "claude-3-5-sonnet-v1"
      messages: [
        {
          role: "user",
          content: content_blocks  # Array con media_block + prompt_block
        }
      ],
      inference_config: {
        temperature: BEDROCK_CONFIG["temperature"],  # 0 per risposte deterministiche
        max_tokens: BEDROCK_CONFIG["max_tokens"]     # Es: 1000
      }
    )
  # Gestione errori: Bedrock ServiceError → DocumentAnalysisError
  # (Wrapping di eccezioni AWS in custom exception per consistency)
  rescue Aws::BedrockRuntime::Errors::ServiceError => e
    raise DocumentAnalysisError, "Bedrock error: #{e.message}"
  rescue StandardError => e
    raise DocumentAnalysisError, "API error: #{e.message}"
  end

  # Estrae il JSON dalla risposta Bedrock
  # 
  # Bedrock ritorna testo, spesso con testo + JSON
  # Esempio risposta: "Ecco i dati: { tipo_documento: \"Cedolino\", ... }"
  # 
  # Questo metodo:
  #   1. Legge il testo della risposta
  #   2. Trova il primo blocco JSON (regex match)
  #   3. Parse il JSON
  #   4. Valida la struttura
  #   5. Ritorna l'oggetto hash
  def extract_json_from_response(response)
    # Accede al testo della risposta
    # response.output.message.content = array di content blocks
    # .first.text = primo blocco, accesso al testo
    text = response.output.message.content.first.text

    # Regex per trovare il primo blocco JSON nel testo
    # /\{[\s\S]*\}/ = match curly brace apertura, any chars (incluso newline), closing brace
    # [\s\S] = any whitespace or non-whitespace (include newline, diverso da .)
    # Più robusto di semplice JSON.parse su testo intero (che fallirebbe se c'è testo aggiuntivo)
    json_match = text.match(/\{[\s\S]*\}/)
    
    # Se nessun JSON trovato, errore
    raise DocumentAnalysisError, "Nessun JSON trovato nella risposta" unless json_match

    # Parse il JSON trovato in oggetto Ruby hash
    parsed = JSON.parse(json_match[0])
    
    # Valida la struttura (deve essere un hash, non array o primitivo)
    validate_json_structure(parsed)
    
    # Ritorna il JSON parsato
    parsed
  # Gestione JSON parsing errors
  rescue JSON::ParsingError => e
    raise DocumentAnalysisError, "JSON parsing error: #{e.message}"
  end

  # Valida che il JSON estratto abbia una struttura sensata
  # (Es: non array, non null, non primitivo)
  #
  # Non validiamo TUTTI i campi (es: che tipo_documento sia string)
  # perché vogliamo flessibilità: Bedrock potrebbe tornare varianti
  # (es: tipo_documento=null se non riconosciuto, numero_pagine=123 vs "123")
  def validate_json_structure(parsed)
    # Non richiediamo che tutti i campi siano presenti, solo che la struttura sia una hash
    # Hash = object in JSON, è il container per i campi
    raise DocumentAnalysisError, "Risposta non è un JSON object" unless parsed.is_a?(Hash)
  end
end

# Custom exception per errori di analisi documenti
# Consente di catturare specificamente questi errori nel controller/job
class DocumentAnalysisError < StandardError; end
