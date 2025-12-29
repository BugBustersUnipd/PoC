class AnalyzeDocumentJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3  # Retry fino a 3 volte in caso di errore

  def perform(document_id)
    doc = Document.find(document_id)
    doc.update(status: "processing")

    # Usa il service per l'analisi
    analysis_data = DocumentAnalysisService.analyze(doc)

    # Salva i risultati
    doc.update!(
      status: "completed",
      doc_type: analysis_data["tipo_documento"],
      ai_data: analysis_data
    )
  rescue DocumentAnalysisError => e
    # Errore di analisi (formato non supportato, Bedrock fallisce, ecc.)
    Rails.logger.error("Document analysis error: #{e.message}")
    doc.update(status: "failed", ai_data: { error: e.message })
  rescue StandardError => e
    # Errori generici: lancia di nuovo per attivare il retry
    Rails.logger.error("Unexpected error analyzing document #{document_id}: #{e.message}")
    raise
  end
end
