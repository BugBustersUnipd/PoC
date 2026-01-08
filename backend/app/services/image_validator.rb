class ImageValidator
  VALID_SIZES = [
    { w: 1024, h: 1024 }, # 1:1 Square - Ideale per icone, avatar, post social
    { w: 1280, h: 720 },  # 16:9 Landscape - Banner, copertine, video thumbnail
    { w: 720, h: 1280 }   # 9:16 Portrait - Stories Instagram/TikTok, mobile vertical
  ].freeze

  def self.validate_size!(width, height)
    is_valid = VALID_SIZES.any? { |s| s[:w] == width && s[:h] == height }

    unless is_valid
      allowed = VALID_SIZES.map { |s| "#{s[:w]}x#{s[:h]}" }.join(", ")
      raise ArgumentError, "Dimensioni non supportate per Nova Canvas. Usa: #{allowed}"
    end
  end
end