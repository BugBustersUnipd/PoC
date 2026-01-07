# Document: documento caricato (PDF, immagine, ecc.) da analizzare con Bedrock IA
#
# STATI DOCUMENTO (enum):
#   - pending: appena caricato, in attesa di analisi
#   - processing: attualmente in analisi da Bedrock (AnalyzeDocumentJob in esecuzione)
#   - completed: analisi terminata con successo, dati estratti in ai_data
#   - failed: analisi fallita (formato non supportato, Bedrock error, ecc.)
#
# CHECKSUM: SHA256 del file → identifica duplicati per azienda
#   - Se carichi lo stesso file due volte, il checksum è uguale
#   - Validation checksum_uniqueness_for_company impedisce caricamento doppio
#   - Utile per: evitare duplicati, deduplicare storage, consistency
#
class Document < ApplicationRecord
  # Relazione obbligatoria: documento appartiene sempre a un'azienda
  belongs_to :company
  
  # ActiveStorage attachment: il file vero e proprio (PDF, immagine)
  # has_one_attached vs has_many_attached:
  #   - has_one_attached: UNO solo file per documento (non array)
  #   - File salvato su disk (dev) o S3 (prod) secondo config/storage.yml
  #   - Accesso: document.original_file.download, .attached?, .content_type, ecc.
  has_one_attached :original_file

  # ENUM: tipo di dato con valori predefiniti
  # enum :status, { pending: "pending", ... } crea metodi:
  #   - doc.pending? = true se status == "pending"
  #   - doc.processing? = true se status == "processing"
  #   - doc.pending! = doc.update(status: "pending")
  # default: "pending" = nuovo documento ha status pending di default
  enum :status, { 
    pending: "pending", 
    processing: "processing", 
    completed: "completed", 
    failed: "failed" 
  }, default: "pending"

  # CALLBACK (hook Rails): esegui questo metodo prima della validazione, solo al create
  # on: :create = non eseguire negli update (checksum non cambia se file non cambia)
  # Prima dei callback, Rails esegue le validazioni, poi salva nel DB
  before_validation :compute_checksum, on: :create

  # VALIDAZIONI: regole che il model DEVE rispettare prima di salvare
  # Se fallisce una validazione, model.save ritorna false, model.errors popola messaggi
  validates :original_file, presence: true  # Il file DEVE essere allegato
  validates :company_id, presence: true    # La company DEVE essere assegnata
  
  # Custom validation (metodo privato): valida il MIME type del file
  # if: -> { condition } = esegui la validazione SOLO se la condizione è true
  # -> { ... } = lambda/Proc (funzione anonima Rails)
  # Qui: valida il MIME type SOLO se un file è stato allegato (original_file.attached?)
  validate :original_file_mime_type, if: -> { original_file.attached? }
  
  # Custom validation: checksum non duplicato per l'azienda
  # Esegui SOLO se checksum è stato calcolato (presente)
  validate :checksum_uniqueness_for_company, if: -> { checksum.present? }

  # METODO PRIVATO: validazione custom checksum
  # Controlla che non esista già un documento con lo stesso checksum per questa azienda
  def checksum_uniqueness_for_company
    return unless company_id

    # Crea uno scope (query helper) per documento con questo checksum
    scope = Document.where(company_id: company_id, checksum: checksum)
    
    # Se questo documento è già salvato nel DB (persisted? = true),
    # escludilo dal check (altrimenti fallisce la validazione al salvataggio)
    # perché? perché il checksum è dello stesso documento!
    scope = scope.where.not(id: id) if persisted?
    
    # Se esiste un altro documento con questo checksum + azienda, aggiungi errore
    # errors.add(:base, msg) = errore a livello di model, non di campo specifico
    if scope.exists?
      errors.add(:base, "Documento già caricato")
    end
  end

  # METODO PRIVATO: callback per calcolare checksum
  # Eseguito PRIMA della validazione (before_validation), solo al create
  # Il checksum serve a identificare il file senza memorizzarlo due volte
  def compute_checksum
    # .attachment_changes["original_file"] = le modifiche PENDENTI non ancora salvate
    # Prima del save, il file è in pendenza, non ancora nel DB
    change = attachment_changes["original_file"]
    return unless change  # Se nessun cambio pendente (es: update senza file), esci

    # Richiedi il modulo Digest (hash cryptografico)
    require "digest"

    # .attachable.tempfile = il file temporaneo caricato (prima del salvataggio su S3/disk)
    # Tempfile: file temporaneo in memoria/disk durante l'upload
    io = change.attachable.tempfile

    # SHA256: funzione hash crittografica che produce stringa unica di 64 caratteri
    # .hexdigest = converte hash a stringa esadecimale (64 caratteri, sicuro per DB)
    self.checksum = Digest::SHA256.file(io.path).hexdigest
  end
    
  private

  # METODO PRIVATO: validazione custom per MIME type
  # Controlla che il file abbia un tipo supportato da Bedrock
  def original_file_mime_type
    # Carica formati supportati da config (bedrock.yml via initializer)
    # ::BEDROCK_CONFIG_ANALYSIS = costante globale caricata all'avvio Rails
    supported = ::BEDROCK_CONFIG_ANALYSIS["supported_formats"]

    # Se il MIME type è nella lista supportati, validazione passa (return = niente errore)
    return if supported.include?(original_file.content_type)

    # Altrimenti aggiungi errore di validazione
    # Errore associato al campo :original_file (frontend vede quale campo ha errore)
    errors.add(:original_file, "formato non supportato (#{original_file.content_type})")
  end

end
