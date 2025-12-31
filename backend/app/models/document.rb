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

  # Callbacks per calcolare checksum quando il file viene allegato
  after_commit :compute_checksum, on: [:create, :update]

  private

  def original_file_mime_type
    supported = ::BEDROCK_CONFIG_ANALYSIS["supported_formats"]

    return if supported.include?(original_file.content_type)

    errors.add(:original_file, "formato non supportato (#{original_file.content_type})")
  end

  def compute_checksum
    return unless original_file.attached?
    return if checksum.present? # Evita di ricalcolare se già presente

    require "digest"
    new_checksum = Digest::SHA256.hexdigest(original_file.download)
    update_column(:checksum, new_checksum) if checksum != new_checksum
  end
end
