# DocumentSerializer - Formattazione JSON per risposte API documenti
#
# Serializza document records con metadati ActiveStorage.
# Include filename da original_file attachment se presente.
#
# Pattern: Serializer con conditional fields
# - filename presente solo se file attached (evita nil errors)
class DocumentSerializer
  # Serializza singolo documento con metadati completi
  #
  # @param document [Document] record con original_file attachment
  #
  # @return [Hash] JSON structure:
  #   {
  #     id: 123,
  #     company_id: 1,
  #     status: "completed",
  #     doc_type: "pdf",
  #     ai_data: {"extracted_text": "...", "summary": "..."},
  #     checksum: "abc123def456...",
  #     created_at: "2024-01-15T10:00:00Z",
  #     updated_at: "2024-01-15T10:05:00Z",
  #     filename: "document.pdf"
  #   }
  def self.serialize(document)
    {
      id: document.id,
      company_id: document.company_id,
      
      # status: stato processing (pending, completed, error)
      status: document.status,
      
      # doc_type: tipo documento (pdf, docx, txt)
      doc_type: document.doc_type,
      
      # ai_data: JSON con dati estratti da Bedrock (text, entities, summary)
      # Struttura varia per tipo documento
      ai_data: document.ai_data,
      
      # checksum: SHA256 file per deduplicazione
      checksum: document.checksum,
      
      created_at: document.created_at.iso8601,
      updated_at: document.updated_at.iso8601,
      
      # Filename condizionale: solo se file attached
      # document.original_file = accessor ActiveStorage (has_one_attached)
      # .attached? = true se file presente nel blob storage
      # .filename = ActiveStorage::Filename object
      # .to_s = converte in String
      # Operatore ternario: condition ? true_value : false_value
      filename: document.original_file.attached? ? document.original_file.filename.to_s : nil
    }
  end

  # Serializza array di documenti
  #
  # @param documents [Array<Document>] array di record
  #
  # @return [Array<Hash>] array JSON structures
  #
  # Esempio:
  #   DocumentSerializer.serialize_collection([doc1, doc2])
  #   # => [{id: 1, filename: "doc1.pdf", ...}, {id: 2, filename: "doc2.pdf", ...}]
  def self.serialize_collection(documents)
    # .map chiama serialize per ogni documento
    # { |doc| ... } = block Ruby single-line
    # Equivalente: documents.map do |doc| serialize(doc) end
    documents.map { |doc| serialize(doc) }
  end
end
