# GeneratedImage - Model ActiveRecord per immagini generate con Amazon Bedrock Nova Canvas
#
# Tiene traccia dei parametri di generazione e salva l'immagine tramite ActiveStorage.
# Ogni immagine appartiene a Company, opzionalmente associata a Conversation.
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
# Dimensioni valide (validate in ImageValidator, non nel model):
#   - 1024x1024: quadrato standard (icone, avatar, post social)
#   - 1280x720: landscape 16:9 (banner, copertine, video thumbnail)
#   - 720x1280: portrait 9:16 (stories Instagram/TikTok, mobile vertical)
#
# Note di implementazione:
#   - Validazione dimensioni NON nel model (troppo rigida, delegata a ImageValidator service)
#   - 1 immagine per conversazione: logica in ImageStorage.save (elimina precedenti)
#   - ActiveStorage gestisce automaticamente nome file, MIME type, checksum
#
# Pattern: Entity con Value Objects
# - width/height/seed sono value objects (immutabili dopo creazione)
# - prompt e model_id per audit trail e riproducibilità
class GeneratedImage < ApplicationRecord
  # belongs_to :company = associazione many-to-one obbligatoria
  # Ogni immagine appartiene a esattamente un'azienda (ownership + multi-tenancy)
  # Rails genera: generated_image.company, generated_image.company=, etc.
  belongs_to :company
  
  # belongs_to :conversation con optional: true
  # optional: true = conversation_id può essere nil
  # Scenario: immagine standalone (non legata a conversazione testuale)
  #
  # Se conversation_id presente:
  # - ImageStorage elimina immagini precedenti (politica: 1 img per conversazione)
  # - UI mostra immagine inline nella conversazione
  belongs_to :conversation, optional: true
  
  # has_one_attached :image = ActiveStorage attachment per file PNG
  # File salvato secondo config/storage.yml:
  # - development: storage/ directory locale
  # - production: Amazon S3 / Azure Blob / Google Cloud Storage
  #
  # Rails genera:
  # - generated_image.image.attached? → true se file presente
  # - generated_image.image.attach(io:, filename:, content_type:)
  # - generated_image.image.purge → elimina file da storage
  #
  # ActiveStorage crea automaticamente:
  # - active_storage_blobs record (metadati file: key, filename, byte_size, checksum)
  # - active_storage_attachments record (join table: record_type, record_id, blob_id)
  has_one_attached :image

  # Validazioni di base
  # validates = regole validazione eseguite prima di save/create
  
  # prompt: descrizione usata per generare immagine (audit trail + riproducibilità)
  # Esempio: "Logo aziendale moderno con colori blu e verde"
  validates :prompt, presence: true
  
  # width: larghezza pixel (validato anche in ImageValidator prima di API call)
  # numericality: verifica che sia numero intero positivo
  # only_integer: true = rifiuta float (1024.5 non valido)
  # greater_than: 0 = deve essere > 0
  validates :width, presence: true, numericality: { only_integer: true, greater_than: 0 }
  
  # height: altezza pixel (stesso pattern di width)
  validates :height, presence: true, numericality: { only_integer: true, greater_than: 0 }
  
  # model_id: identifica modello Bedrock usato
  # Esempio: "amazon.nova-canvas-v1:0"
  # Importante per audit: sapere quale versione modello ha generato immagine
  validates :model_id, presence: true
  
  # NOTA IMPORTANTE: Non validiamo dimensioni esatte qui (1024x1024, 1280x720, 720x1280)
  # Ragioni:
  # 1. Troppo rigido: se Amazon aggiunge dimensioni, dovremmo modificare model
  # 2. Separazione concerns: ImageValidator service gestisce logica business dimensioni
  # 3. Model valida solo constraint DB (presence, type), non business rules
  #
  # ImageValidator.validate_size! solleva ArgumentError se dimensioni invalide
  # PRIMA di chiamare API Bedrock (fail-fast, evita costi API inutili)
end

