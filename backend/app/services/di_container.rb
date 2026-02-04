# DiContainer - Dependency Injection Container
#
# Punto centralizzato per costruire e configurare tutte le dipendenze dell'applicazione.
#
# Vantaggi:
# - Separa costruzione oggetti dall'uso (Dependency Inversion Principle)
# - Facilita testing: puoi sostituire implementazioni con mock
# - Configurazione centralizzata delle dipendenze
#
# Standard/costrutti classici di Ruby utilizzati:
# - class << self: apre singleton class per definire metodi di classe
# - attr_writer: genera setter per variabili di classe (@ai_text_generator_provider=), in questo caso non usato,
#   ma visto che sono cose per noi nuove volevamo provare a impostarle e dunque capire se possono essere utili o meno, in caso come farle funzionare.
# - ||=: memoization, crea istanza solo alla prima chiamata
# - &.: safe navigation operator, chiama .call solo se provider non è nil
#
# Anche se per il PoC non é richiesto, per fare palestra e dunque provare e speriementare ipotizziamo:
# Uso in produzione:
#   service = DiContainer.ai_service  # Restituisce singleton configurato
#
# Uso nei test (sostituzione con mock):
#   DiContainer.ai_text_generator_provider = -> { MockGenerator.new }
#   DiContainer.reset!  # Svuota cache per usare nuovo provider
class DiContainer
  class << self
    # Permette di registrare provider personalizzati per ogni dipendenza
    # Un provider è un Proc/lambda che restituisce l'istanza desiderata
    # Es: DiContainer.ai_text_generator_provider = -> { MyCustomGenerator.new }
    attr_writer :ai_text_generator_provider, :conversation_manager_provider, :prompt_builder_provider,
                :image_validator_provider, :image_generator_provider, :image_storage_provider
  end

  # === SERVIZI ORCHESTRATORI ===
  # Questi servizi coordinano più componenti per implementare use case complessi

  # Servizio per generazione testo via AI
  # Coordina: costruzione prompt, chiamata API, gestione conversazioni
  # @return [AiService] istanza singleton del servizio
  def self.ai_service
    @ai_service ||= AiService.new(
      text_generator: ai_text_generator,       # Chiamate Bedrock API
      conversation_manager: conversation_manager, # Persistenza messaggi
      prompt_builder: prompt_builder           # Formattazione prompt
    )
  end

  # Servizio per generazione immagini via AI
  # Coordina: validazione, chiamata API, storage
  # @return [ImageService] istanza singleton del servizio
  def self.image_service
    @image_service ||= ImageService.new(
      image_validator: image_validator,  # Verifica dimensioni supportate
      image_generator: image_generator,  # Chiamate Bedrock Nova Canvas
      image_storage: image_storage       # Salvataggio DB + ActiveStorage
    )
  end

  # === DIPENDENZE PER AI SERVICE ===

  # Component per chiamate API Amazon Bedrock Converse
  # @return [AiTextGenerator] istanza che esegue chiamate HTTP a Bedrock
  def self.ai_text_generator
    # - Usa provider custom se definito, altrimenti istanza default
    # - &. evita errore se @provider è nil
    @ai_text_generator ||= (@ai_text_generator_provider&.call || AiTextGenerator.new)
  end

  # Component per gestione conversazioni (CRUD messaggi)
  # @return [ConversationManager] istanza per persistenza conversazioni
  def self.conversation_manager
    @conversation_manager ||= (@conversation_manager_provider&.call || ConversationManager.new)
  end

  # Component per costruzione prompt AI
  # @return [PromptBuilder] istanza per formattare system prompt e messaggi
  def self.prompt_builder
    @prompt_builder ||= (@prompt_builder_provider&.call || PromptBuilder.new)
  end

  # === DIPENDENZE PER IMAGE SERVICE ===

  # Component per validazione dimensioni immagine
  # @return [ImageValidator] istanza che verifica dimensioni supportate da Nova Canvas
  def self.image_validator
    @image_validator ||= (@image_validator_provider&.call || ImageValidator.new)
  end

  # Component per chiamate API Amazon Bedrock Nova Canvas
  # @return [ImageGenerator] istanza che esegue chiamate HTTP a Bedrock
  def self.image_generator
    @image_generator ||= (@image_generator_provider&.call || ImageGenerator.new)
  end

  # Component per storage immagini generate
  # @return [ImageStorage] istanza per salvataggio DB + ActiveStorage
  def self.image_storage
    @image_storage ||= (@image_storage_provider&.call || ImageStorage.new)
  end

  # Reset di tutte le istanze cachate
  # Utile nei test per forzare ricreazione con nuovi provider
  # Chiamare dopo aver settato provider custom
  def self.reset!
    @ai_service = nil
    @image_service = nil
    @ai_text_generator = nil
    @conversation_manager = nil
    @prompt_builder = nil
    @image_validator = nil
    @image_generator = nil
    @image_storage = nil
  end
end