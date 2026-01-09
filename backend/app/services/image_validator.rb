# ImageValidator - Validazione dimensioni supportate da Amazon Nova Canvas
#
# Nova Canvas supporta solo aspect ratio specifici ottimizzati:
# - 1:1 (1024x1024) = Square, per icone/avatar/post social
# - 16:9 (1280x720) = Landscape, per banner/copertine/video thumbnail
# - 9:16 (720x1280) = Portrait, per Stories Instagram/TikTok/mobile vertical
#
# Altre dimensioni (es. 800x600, 512x512) verrebbero rifiutate da Bedrock
# con ValidationException.
#
# Pattern: Validator Service
# - Singola responsabilità: validare input prima di chiamate costose
# - Fail-fast: solleva eccezione subito se dimensioni invalide
# - Migliora UX: errore chiaro con dimensioni supportate
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
  #
  # Esempio uso freeze:
  #   arr = [1, 2].freeze
  #   arr << 3  # => RuntimeError: can't modify frozen Array
  VALID_SIZES = [
    { w: 1024, h: 1024 }, # 1:1 Square - Ideale per icone, avatar, post social
    { w: 1280, h: 720 },  # 16:9 Landscape - Banner, copertine, video thumbnail
    { w: 720, h: 1280 }   # 9:16 Portrait - Stories Instagram/TikTok, mobile vertical
  ].freeze

  # Valida che dimensioni fornite siano supportate da Nova Canvas
  #
  # Metodo con ! suffix (bang method) = convenzione Ruby per:
  # - Metodi che modificano oggetto in-place (es. array.sort!)
  # - Metodi che sollevano eccezioni invece di ritornare true/false
  #
  # validate_size! solleva eccezione se dimensioni invalide (niente return value)
  # Alternativa validate_size (senza !) ritornerebbe true/false
  #
  # @param width [Integer] larghezza in pixel
  # @param height [Integer] altezza in pixel
  #
  # @return [nil] ritorna nil se validazione passa (void method)
  #
  # @raise [ArgumentError] se combinazione width/height non in VALID_SIZES
  #
  # Esempio:
  #   validator.validate_size!(1024, 1024)  # OK, nessun errore
  #   validator.validate_size!(800, 600)    # ArgumentError: "Dimensioni non supportate..."
  def validate_size!(width, height)
    # .any? ritorna true se almeno un elemento array soddisfa condizione nel block
    # { |s| ... } = block Ruby (funzione anonima, equivalente a lambda/arrow function)
    # s = variabile block che itera su ogni elemento VALID_SIZES
    # s[:w] accede a chiave :w del Hash corrente
    # && = AND logico, entrambe condizioni devono essere vere
    # any? + block = pattern funzionale per "esiste almeno uno"
    is_valid = VALID_SIZES.any? { |s| s[:w] == width && s[:h] == height }

    # unless = if negato (esegui se condizione è falsa)
    # unless condition equivale a if !condition
    # Preferito quando condizione check è "assenza di qualcosa"
    unless is_valid
      # .map trasforma ogni elemento array applicando block
      # Qui converte [{w: 1024, h: 1024}, ...] in ["1024x1024", "1280x720", ...]
      # .join(", ") unisce array in stringa separata da virgole
      # Risultato: "1024x1024, 1280x720, 720x1280"
      allowed = VALID_SIZES.map { |s| "#{s[:w]}x#{s[:h]}" }.join(", ")
      
      # raise = solleva eccezione
      # ArgumentError = eccezione Ruby standard per parametri invalidi
      # Messaggio include dimensioni supportate per facilitare fix utente
      raise ArgumentError, "Dimensioni non supportate per Nova Canvas. Usa: #{allowed}"
    end
    
    # Se is_valid è true, metodo termina senza errori
    # Return implicito nil (non serve return statement)
  end
end