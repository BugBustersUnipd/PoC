# ImageValidator - Validazione dimensioni supportate da Amazon Nova Canvas

class ImageValidator
  # Costante contenente dimensioni valide per Nova Canvas
  #
  # Sintassi Ruby:
  #   CONSTANT = convenzione nome per valori immutabili
  #   [{key: value}, ...] = Array di Hash
  #   .freeze = rende array immutabile (nessuna modifica runtime)
  #
  # freeze è importante per:
  # - Sicurezza: previene modifiche accidentali (VALID_SIZES << {w: 999, h: 999})
  # - Performance: Ruby può ottimizzare costanti frozen
  # - Semantica: dichiara intent "questo non cambia mai"

  VALID_SIZES = [
    { w: 1024, h: 1024 }, # 1:1 Square - Ideale per icone, avatar, post social
    { w: 1280, h: 720 },  # 16:9 Landscape - Banner, copertine, video thumbnail
    { w: 720, h: 1280 }   # 9:16 Portrait - Stories Instagram/TikTok, mobile vertical
  ].freeze

  # Valida che dimensioni fornite siano supportate da Nova Canvas
  def validate_size!(width, height)
    # .any? ritorna true se almeno un elemento array soddisfa condizione nel block
    # { |s| ... } = block Ruby (funzione anonima, equivalente a lambda/arrow function)
    # s = variabile block che itera su ogni elemento VALID_SIZES
    # s[:w] accede a chiave :w del Hash corrente
    is_valid = VALID_SIZES.any? { |s| s[:w] == width && s[:h] == height }

    # unless = if negato (esegui se condizione è falsa)
    unless is_valid
      # .map trasforma ogni elemento array applicando block
      # Qui converte [{w: 1024, h: 1024}, ...] in ["1024x1024", "1280x720", ...]
      # .join(", ") unisce array in stringa separata da virgole
      # Risultato: "1024x1024, 1280x720, 720x1280"
      allowed = VALID_SIZES.map { |s| "#{s[:w]}x#{s[:h]}" }.join(", ")
      
      # ArgumentError = eccezione Ruby standard per parametri invalidi
      # Messaggio include dimensioni supportate per facilitare fix utente
      raise ArgumentError, "Dimensioni non supportate per Nova Canvas. Usa: #{allowed}"
    end
    
    # Se is_valid è true, metodo termina senza errori
    # Return implicito nil (non serve return statement)
  end
end