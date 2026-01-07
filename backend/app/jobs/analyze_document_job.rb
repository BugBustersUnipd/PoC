# AnalyzeDocumentJob
# 
# Background job per analizzare documenti con Bedrock IA (attività lunga).
# Flow:
#   1. DocumentsController.create → AnalyzeDocumentJob.perform_later(doc.id) (schedula subito)
#   2. Worker prende il job dalla coda (Sidekiq/Redis) quando disponibile
#   3. Esegue perform(doc.id): carica documento, invia a Bedrock, salva risultati
#   4. Frontend poll periodico per verificare status documento (pending → processing → completed/failed)
#
# RETRY: sidekiq_options retry: 3 = riprova fino a 3 volte se errore (es: Bedrock timeout)
class AnalyzeDocumentJob < ApplicationJob
  # queue_as: quale coda usare (default = "default", ma puoi averne più per priorità)
  queue_as :default
  
  # Configurazione Sidekiq (Redis background worker)
  # retry: 3 = se il job fallisce, Sidekiq lo riproverà automaticamente 3 volte con backoff
  #   Tentativi totali: 1 (iniziale) + 3 (retry) = 4 tentativi max
  sidekiq_options retry: 3

  # perform(document_id): metodo principale del job, eseguito dal worker
  # 
  # IMPORTANTE: gli argomenti devono essere serializzabili (JSON):
  #   - Tipi semplici: id, string, numero ✓
  #   - Oggetti interi: NO (non serializzabili) → passa sempre ID, poi carica in job
  #   - Perché? Il job viene salvato in Redis, va serializzato per il storage
  def perform(document_id)
    # .find(id) = SELECT * WHERE id=id, solleva RecordNotFound se non esiste
    # Possibile che il documento sia stato cancellato tra quando il job fu creato e ora
    doc = Document.find(document_id)
    
    # return unless doc: se doc è nil, esci dalla funzione (salto tutto il codice dopo)
    # Questo è una "early return" Rails pattern per evitare indentazione profonda
    return unless doc
    
    # .update_column(field, value): UPDATE diretto senza validazioni (per velocità)
    # Diverso da .update!() che chiama validazioni e trigger Rails
    # Usiamo .update_column qui perché vogliamo SOLO aggiornare lo status, velocemente
    doc.update_column(:status, "processing")

    # Delega a DocumentAnalysisService: estrae dati dal documento usando Bedrock AI
    # Service pattern: logica complessa in classe separata (non nel job)
    # Perché? Riutilizzabile da altri controller/job, testabile isolato
    analysis_data = DocumentAnalysisService.analyze(doc)

    # .update!(): UPDATE con validazioni
    # ! (bang) = solleva eccezione se fallisce (diverso da .update() che ritorna false)
    # Usiamo ! qui perché vogliamo che il job fallisca se il salvataggio fallisce
    doc.update!(
      status: "completed",
      doc_type: analysis_data["tipo_documento"],  # Es: "Cedolino", "Contratto", ecc.
      ai_data: analysis_data,  # JSON con tutti i dati estratti
      updated_at: Time.current  # Timestamp attuale
    )
  
  # rescue X => e: cattura eccezioni di tipo X e salvale in variabile e
  rescue DocumentAnalysisError => e
    # Errore previsto da Bedrock/analisi (formato non supportato, API error, ecc.)
    # Log per debug
    Rails.logger.error("Document analysis error: #{e.message}")
    
    # .update_columns (non update!): aggiorna campi senza validazioni, ignora errori
    # &. = safe navigation: chiama il metodo SOLO se doc non è nil (evita NoMethodError)
    # Perché? Se per qualche motivo doc non esiste più, non vogliamo crash il job
    doc&.update_columns(
      status: "failed",
      ai_data: { error: e.message },  # Salva il messaggio errore per debug frontend
      updated_at: Time.current
    )
    # Nota: Non fare "raise" qui! Se lo facessimo, Sidekiq ripeterebbe 3 volte.
    #       Vogliamo loggare e basta (errore non recuperabile)
  
  rescue StandardError => e
    # Errore INASPETTATO (bug, network crash, memoria insufficiente, ecc.)
    # StandardError = catch-all per errori non previsti
    Rails.logger.error("Unexpected error analyzing document #{document_id}: #{e.message}")
    
    # "raise" SENZA argomenti = ri-solleva l'eccezione attuale
    # Questo dice a Sidekiq: "Retry questo job, è un errore temporaneo forse"
    # Differenza con DocumentAnalysisError rescue: qui vogliamo che Sidekiq riprovi
    raise
  end
end
