class AnalyzeDocumentJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3  # Retry fino a 3 volte in caso di errore

  def perform(document_id)
    doc = Document.find(document_id)
    return unless doc
    doc.update_column(:status, "processing")

    # Usa il service per l'analisi
    analysis_data = DocumentAnalysisService.analyze(doc)

    # Salva i risultati
    doc.update!(
      status: "completed",
      doc_type: analysis_data["tipo_documento"],
      ai_data: analysis_data,
      updated_at: Time.current
    )
  rescue DocumentAnalysisError => e
    Rails.logger.error("Document analysis error: #{e.message}")
    doc&.update_columns(
      status: "failed",
      ai_data: { error: e.message },
      updated_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error("Unexpected error analyzing document #{document_id}: #{e.message}")
    raise
  end
end
