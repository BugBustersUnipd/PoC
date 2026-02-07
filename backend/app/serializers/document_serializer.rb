# Serializza documenti analizzati
class DocumentSerializer
  # Ritorna metadati documento + dati estratti da AI
  def self.serialize(document)
    {
      id: document.id,
      company_id: document.company_id,
      status: document.status,              # pending/processing/completed/failed
      doc_type: document.doc_type,          # pdf/docx/txt
      ai_data: document.ai_data,            # dati estratti da Bedrock
      checksum: document.checksum,          # SHA256 per deduplicazione
      created_at: document.created_at.iso8601,
      updated_at: document.updated_at.iso8601,
      filename: document.original_file.attached? ? document.original_file.filename.to_s : nil
    }
  end

  # Serializza array di documenti
  def self.serialize_collection(documents)
    documents.map { |doc| serialize(doc) }
  end
end
