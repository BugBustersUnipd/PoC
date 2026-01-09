# Document - Model ActiveRecord per documenti analizzati con Bedrock
#
# Rappresenta documento caricato (PDF, DOCX, TXT) con estrazione dati IA.
# Usa ActiveStorage per file originale e background job per analisi.
#
# Relazioni:
# - belongs_to :company (required)
# - has_one_attached :original_file (ActiveStorage)
#
# Colonne database:
# - company_id (integer, foreign key, required)
# - status (enum): pending | processing | completed | failed
# - doc_type (string): "pdf", "docx", "txt"
# - ai_data (json): dati estratti da Bedrock (text, entities, summary)
# - checksum (string): SHA256 hash file per deduplicazione
# - created_at, updated_at (timestamp, auto)
#
# Workflow:
# 1. Upload file → status=pending
# 2. Background job AnalyzeDocumentJob → status=processing
# 3. Bedrock estrae dati → ai_data popolato, status=completed
# 4. Errore → status=failed
#
# Pattern: Aggregate Root con State Machine
class Document < ApplicationRecord
  # belongs_to :company = associazione many-to-one
  # Ogni documento appartiene a un'azienda
  belongs_to :company
  
  # has_one_attached :original_file = ActiveStorage attachment
  # File salvato su disco (dev) o S3 (prod) secondo config/storage.yml
  # Rails genera: document.original_file, document.original_file.attach(...), etc.
  has_one_attached :original_file

  # enum :status = definisce stati documento come colonna enum
  # Sintassi Ruby 7+: enum :column_name, {key: "value"}, options
  #
  # Stati:
  # - pending: caricato ma non ancora processato
  # - processing: AnalyzeDocumentJob in esecuzione
  # - completed: analisi completata, ai_data popolato
  # - failed: errore durante analisi
  #
  # Rails genera metodi:
  # - document.pending? → true se status == "pending"
  # - document.processing! → imposta status = "processing"
  # - Document.completed → scope per tutti documenti completed
  #
  # default: "pending" = status iniziale per nuovi record
  enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" }, default: "pending"

  # Callback: eseguito PRIMA di validazioni, solo su :create (non update)
  # before_validation = hook ActiveRecord lifecycle
  # on: :create = esegui solo per record nuovi (non su update)
  #
  # Ordine lifecycle Rails:
  # 1. before_validation
  # 2. validations
  # 3. after_validation
  # 4. before_save
  # 5. before_create (solo create)
  # 6. INSERT SQL
  # 7. after_create
  # 8. after_save
  #
  # compute_checksum = calcola SHA256 hash file per deduplicazione
  before_validation :compute_checksum, on: :create

  # Validazioni standard
  validates :original_file, presence: true  # File deve essere attached
  validates :company_id, presence: true     # Foreign key obbligatoria
  
  # Validazioni custom con metodi
  # validate (singolare) = chiama metodo custom per validazione complessa
  # if: -> { ... } = lambda condition, esegui solo se true
  #
  # original_file_mime_type: verifica formato file supportato
  validate :original_file_mime_type, if: -> { original_file.attached? }
  
  # checksum_uniqueness_for_company: previene upload duplicati
  validate :checksum_uniqueness_for_company, if: -> { checksum.present? }

  # Validazione custom: verifica unicità checksum per company
  #
  # Previene stesso file caricato più volte dalla stessa azienda.
  # Due aziende diverse POSSONO caricare stesso file (checksum identico OK).
  #
  # Logica:
  # 1. Cerca documenti stessa company con stesso checksum
  # 2. Escludi documento corrente (se update)
  # 3. Se trovati, aggiungi errore
  def checksum_uniqueness_for_company
    # Guard clause: esce se company_id nil (belongs_to validation catchersà)
    return unless company_id

    # Query documenti duplicati
    # .where(company_id:, checksum:) = trova record con questi valori
    scope = Document.where(company_id: company_id, checksum: checksum)
    
    # Se record già salvato (update), escludi se stesso dalla query
    # .persisted? = true se record ha ID (già salvato in DB)
    # .where.not(id:) = SQL WHERE id != ?
    scope = scope.where.not(id: id) if persisted?
    
    # .exists? = true se query ritorna almeno un record (SQL SELECT 1 ... LIMIT 1)
    if scope.exists?
      # .add(:base, msg) = aggiunge errore generico al record (non a campo specifico)
      # :base errori mostrati come "Document già caricato" senza associazione campo
      errors.add(:base, "Documento già caricato")
    end
  end

  # Callback: calcola SHA256 checksum file
  #
  # Checksum = fingerprint univoco file, identico se contenuto identico.
  # Usato per deduplicazione (stesso file caricato due volte).
  #
  # SHA256 = algoritmo hash crittografico:
  # - Input: file qualsiasi dimensione
  # - Output: 64 caratteri hex (256 bit)
  # - Stessa input → stesso output (deterministico)
  # - Collision resistance: praticamente impossibile due file diversi → stesso hash
  def compute_checksum
    # attachment_changes = Hash ActiveStorage con modifiche pending
    # ["original_file"] = accede a change object per original_file attachment
    change = attachment_changes["original_file"]
    
    # Guard clause: nessun file attached, esci
    return unless change

    # require "digest" = carica libreria Ruby standard per hash
    # Digest::SHA256 = classe per SHA256 hashing
    require "digest"

    # .attachable.tempfile = accede a file temporaneo upload
    # Rails salva upload in temp file prima di persistence finale
    io = change.attachable.tempfile

    # Digest::SHA256.file(path) = calcola hash intero file
    # .hexdigest = ritorna hash come stringa 64 caratteri hex
    # Esempio: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    self.checksum = Digest::SHA256.file(io.path).hexdigest
  end

  private

  # Validazione custom: verifica MIME type file supportato
  #
  # Bedrock supporta solo certi formati per document analysis.
  # Lista formati in config/bedrock.yml BEDROCK_CONFIG_ANALYSIS["supported_formats"]
  #
  # MIME types comuni:
  # - "application/pdf" = PDF
  # - "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = DOCX
  # - "text/plain" = TXT
  def original_file_mime_type
    # :: accede a costante globale caricata da bedrock.yml
    # ["supported_formats"] = array MIME types (es. ["application/pdf", ...])
    supported = ::BEDROCK_CONFIG_ANALYSIS["supported_formats"]

    # .content_type = MIME type file rilevato da ActiveStorage
    # .include? = true se array contiene valore
    # return = guard clause, esce se MIME type supportato
    return if supported.include?(original_file.content_type)

    # MIME type non supportato: aggiungi errore
    # :original_file = simbolo campo, errore associato a questo campo
    # Messaggio include content_type per debug ("formato non supportato (image/jpeg)")
    errors.add(:original_file, "formato non supportato (#{original_file.content_type})")
  end
end
