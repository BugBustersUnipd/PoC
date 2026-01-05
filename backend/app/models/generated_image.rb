# GeneratedImage
#
# Model per le immagini generate con Amazon Bedrock Nova Canvas.
# Tiene traccia dei parametri di generazione e salva l'immagine tramite ActiveStorage.
#
# Relazioni:
#   - company (required): azienda proprietaria dell'immagine
#   - conversation (optional): conversazione testuale associata
#     Se impostata, può esistere solo 1 immagine per conversazione (gestito in ImageService)
#   - image (ActiveStorage): file PNG generato, salvato su disco (dev) o S3 (prod)
#
# Colonne database:
#   - prompt (text, required): descrizione usata per generare l'immagine
#   - width (integer, required): larghezza in pixel (deve essere 1024, 1280 o 720)
#   - height (integer, required): altezza in pixel (deve essere 1024, 720 o 1280)
#   - model_id (string, required): ID modello Bedrock usato (es. "amazon.nova-canvas-v1:0")
#   - quality (string, default "standard"): qualità generazione (non più usato da Nova Canvas)
#   - company_id (integer, required, foreign key)
#   - conversation_id (integer, optional, foreign key)
#
# Dimensioni valide (validate in ImageService, non nel model):
#   - 1024x1024: quadrato standard (icone, avatar, post social)
#   - 1280x720: landscape 16:9 (banner, copertine, video thumbnail)
#   - 720x1280: portrait 9:16 (stories Instagram/TikTok, mobile vertical)
#
# Note di implementazione:
#   - Validazione dimensioni NON nel model (troppo rigida, delegata a ImageService)
#   - 1 immagine per conversazione: logica in ImageService.save_generated_image
#   - ActiveStorage gestisce automaticamente nome file, MIME type, checksum
class GeneratedImage < ApplicationRecord
  # Relazione obbligatoria: ogni immagine appartiene a un'azienda
  belongs_to :company
  
  # Relazione opzionale: immagine può essere associata a una conversazione testuale
  # Se conversation_id è presente, ImageService elimina immagini precedenti (1 per conversazione)
  belongs_to :conversation, optional: true
  
  # ActiveStorage attachment: salva l'immagine PNG generata
  # File salvato su disco locale (development) o S3 (production) secondo config/storage.yml
  # Filename pattern: "nova_{id}_{seed}.png" (es. "nova_123_456789.png")
  has_one_attached :image

  # Validazioni di base
  validates :prompt, presence: true # Descrizione usata per generare l'immagine
  validates :width, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :height, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :model_id, presence: true # Es. "amazon.nova-canvas-v1:0"
  
  # NOTA: Non validiamo dimensioni esatte qui (1024x1024, etc.) perché troppo rigido
  #       ImageService gestisce validazione specifica prima della generazione
  #       Questo permette flessibilità futura se Amazon aggiungerà altre dimensioni
end

