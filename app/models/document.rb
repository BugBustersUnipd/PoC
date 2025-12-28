class Document < ApplicationRecord
  # Associazioni
  has_one_attached :original_file

  # Estados possibili
  enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" }, default: "pending"

  # Validazioni
  validates :original_file, presence: true
  validate :original_file_mime_type, if: -> { original_file.attached? }

  private

  def original_file_mime_type
    supported = ::BEDROCK_CONFIG_ANALYSIS["supported_formats"]

    return if supported.include?(original_file.content_type)

    errors.add(:original_file, "formato non supportato (#{original_file.content_type})")
  end
end
