class Document < ApplicationRecord
  # Associazioni
  belongs_to :company
  has_one_attached :original_file

  # Estados possibili
  enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" }, default: "pending"

  # Validazioni
  validates :original_file, presence: true
  validates :company_id, presence: true
  validate :original_file_mime_type, if: -> { original_file.attached? }
  validate :checksum_uniqueness_for_company, if: -> { checksum.present? }


  # Calcola il checksum del file prima della validazione
  before_validation :compute_checksum, if: -> { original_file.attached? }

  private

  def original_file_mime_type
    supported = ::BEDROCK_CONFIG_ANALYSIS["supported_formats"]

    return if supported.include?(original_file.content_type)

    errors.add(:original_file, "formato non supportato (#{original_file.content_type})")
  end

  def compute_checksum
    return unless original_file.attached?

    require "digest"

    uploaded_file = original_file.blob.instance_variable_get(:@record)

    if uploaded_file.respond_to?(:tempfile)
      self.checksum = Digest::SHA256.file(uploaded_file.tempfile.path).hexdigest
    end
  end

  def checksum_uniqueness_for_company
    return unless company_id

    if Document.where(company_id: company_id, checksum: checksum).exists?
      errors.add(:base, "Documento già caricato")
    end
  end
end
