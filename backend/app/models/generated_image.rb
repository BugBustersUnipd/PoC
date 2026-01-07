# GeneratedImage: immagine generata con Amazon Bedrock Nova Canvas
#
# Model che tiene traccia di OGNI immagine generata:
#   - Dati della richiesta: prompt, dimensioni, seed
#   - Metadati: quale modello Bedrock, quando creata
#   - File vero: salvato con ActiveStorage (PNG binario)
#
# RELAZIONI:
#   - company (required): azienda proprietaria dell'immagine (ownership/segregazione)
#   - conversation (optional): conversazione testuale associata (link chat↔immagine)
#     Politica ImageService: 1 sola immagine per conversazione (l'ultima generata sovrascrive)
#   - image (ActiveStorage): il file PNG vero e proprio (non memorizzato in DB come blob)
#
# COLONNE DATABASE:
#   - id: primary key (auto-increment)
#   - company_id: foreign key a companies (required)
#   - conversation_id: foreign key a conversations (optional)
#   - prompt: descrizione usata per la generazione (es: "Un gatto che suona il pianoforte")
#   - width, height: dimensioni in pixel (es: 1024, 1280, 720)
#   - model_id: ID modello Bedrock (es: "amazon.nova-canvas-v1:0") → tracciabilità versione
#   - seed: seed numerico usato per la generazione (> 0 = deterministico, stesso seed = stessa immagine)
#   - quality: legacy field (non più usato da Nova Canvas, rimane per compatibilità)
#   - created_at, updated_at: timestamp Rails (auto-managed)
#
# DIMENSIONI SUPPORTATE (validate in ImageService, non qui):
#   - 1024x1024: quadrato (icone, avatar, profilo social)
#   - 1280x720: landscape 16:9 (banner, header, video thumbnail)
#   - 720x1280: portrait 9:16 (stories Instagram/TikTok, mobile vertical)
#   Perché non validare dimensioni nel model? → Permette flessibilità
#     Se Amazon aggiunge 512x512 domani, basta aggiornare ImageService.VALID_SIZES
#     Senza dover lanciare migration per aggiungere enumerazione
#
class GeneratedImage < ApplicationRecord
  # Relazione obbligatoria (required): ogni immagine APPARTIENE a un'azienda
  # Ha un company_id non nullable nel DB
  # Accesso: generated_image.company → carica la Company associata
  belongs_to :company
  
  # Relazione opzionale (optional: true): immagine PUÒ essere associata a una conversazione
  # optional: true = conversation_id PUÒ essere NULL
  # Logica ImageService: se conversation_id presente, elimina immagini vecchie della stessa conversa
  # Uso case: "genera immagine per questa chat, l'ultima generazione sovrascrive le precedenti"
  belongs_to :conversation, optional: true
  
  # ActiveStorage attachment: il file PNG vero e proprio
  # File non memorizzato nella colonna "image" del DB (quello è metadata)
  # Bensì su filesystem (development/test) o S3 (production) secondo config/storage.yml
  # Accesso: generated_image.image.download, .attached?, .content_type, .filename, .byte_size, ecc.
  # URL: rails_blob_path(generated_image.image, disposition: "inline") → URL temporaneo firmato
  has_one_attached :image

  # VALIDAZIONI: regole che il model DEVE rispettare prima di salvare
  # Nota: dimensioni NON validate qui (delegato a ImageService.validate_size!)
  # Perché? I controller/service dovrebbero validare PRIMA del salvataggio (fail-fast)
  #        Nel model metto solo validazioni "business logic" base
  
  validates :prompt, presence: true  # Prompt DEVE essere presente (non vuoto)
  
  # numericality: only_integer: true = deve essere numero intero (0, 1, -5, non 1.5 o stringa)
  # greater_than: 0 = deve essere > 0 (larghezza/altezza negativa ha senso? NO!)
  validates :width, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :height, presence: true, numericality: { only_integer: true, greater_than: 0 }
  
  validates :model_id, presence: true  # Quale modello Bedrock fu usato (per tracking/debug)
  
  # NON validate dimensioni esatte qui (1024, 1280, 720):
  #   - ImageService.validate_size! già lo fa (thrown ArgumentError se invalido)
  #   - Model validation = più tardi (già abbiamo dati nel DB poi?)
  #   - Service validation = prima del salvataggio (fail-fast, efficiente)
  #   - Flessibilità futura: se Amazon aggiunge nuove dimensioni, aggiorna solo ImageService
end

