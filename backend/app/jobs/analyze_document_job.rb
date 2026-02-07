# AnalyzeDocumentJob - Background job per analisi documenti con Amazon Bedrock
#
# Questo job processa documenti caricati in modo asincrono:
# 1. Carica documento dal DB
# 2. Chiama DocumentAnalysisService (estrazione testo, entities, summary via Bedrock)
# 3. Aggiorna status e ai_data
# 4. Gestisce errori con retry automatico
#
# Background Job (Asynchronous Processing)
# - Upload file è sincrono (veloce)
# - Analisi Bedrock è asincrona (lenta, 10-30 secondi per PDF grandi)
# - User riceve response immediata, polling per status update
#
class AnalyzeDocumentJob < ApplicationJob
  def perform(document_id)
    # Carica documento dal DB
    # .find lancia ActiveRecord::RecordNotFound se ID non esiste
    doc = Document.find(document_id)
    
    # Guard clause: esci se documento nil (non dovrebbe succedere con find)
    return unless doc
    
    # update_column = UPDATE SQL diretta senza callbacks/validations
    # Più veloce di update! quando cambi solo 1 campo
    # status = "processing" indica che analisi è in corso
    doc.update_column(:status, "processing")

    # Chiama service per analisi documento
    # DocumentAnalysisService.analyze:
    # 1. Legge file da ActiveStorage
    # 2. Chiama Bedrock InvokeModel per estrazione dati
    # 3. Ritorna Hash con: tipo_documento, extracted_text, entities, summary
    analysis_data = DocumentAnalysisService.analyze(doc)

    # Salva risultati analisi nel DB
    # update! = UPDATE con validazioni, solleva eccezione se fallisce
    doc.update!(
      status: "completed",                       # Analisi completata con successo
      doc_type: analysis_data["tipo_documento"], # Es. "pdf", "docx", "txt"
      ai_data: analysis_data,                    # JSON con tutti dati estratti
      updated_at: Time.current                   # Timestamp aggiornamento
    )
    
  # rescue = exception handling per errori specifici
  # DocumentAnalysisError = custom exception da DocumentAnalysisService
  # Sollevato per: formato non supportato, file corrotto, errore Bedrock
  rescue DocumentAnalysisError => e
    # Log errore per debug (visibile in log/production.log)
    # Rails.logger livelli: debug < info < warn < error < fatal
    Rails.logger.error("Document analysis error: #{e.message}")
    
    # &. = safe navigation operator, chiama update_columns solo se doc non nil
    # update_columns = UPDATE SQL diretta multipla senza callbacks
    # Più veloce di update! quando cambi più campi e non servono validazioni
    doc&.update_columns(
      status: "failed",           # Analisi fallita
      ai_data: { error: e.message }, # Salva messaggio errore per frontend
      updated_at: Time.current
    )
    
  # rescue StandardError = cattura tutti altri errori Ruby
  rescue StandardError => e
    # Log errore inaspettato
    Rails.logger.error("Unexpected error analyzing document #{document_id}: #{e.message}")
    # raise = rilancia eccezione
    raise
  end
end
