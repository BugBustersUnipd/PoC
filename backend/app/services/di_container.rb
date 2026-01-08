# Dependency Injection Container
# Contenitore per gestire le dipendenze dell'applicazione
# Costruisce l'intero grafo di oggetti iniettando dipendenze nei servizi
# Rispetta DIP fornendo astrazioni invece di implementazioni concrete

class DiContainer
  # Servizi principali (orchestratori)
  def self.ai_service
    @ai_service ||= AiService.new(
      text_generator: ai_text_generator,
      conversation_manager: conversation_manager,
      prompt_builder: prompt_builder
    )
  end

  def self.image_service
    @image_service ||= ImageService.new(
      image_validator: image_validator,
      image_generator: image_generator,
      image_storage: image_storage
    )
  end

  # Dipendenze per AiService
  def self.ai_text_generator
    @ai_text_generator ||= AiTextGenerator.new
  end

  def self.conversation_manager
    @conversation_manager ||= ConversationManager.new
  end

  def self.prompt_builder
    @prompt_builder ||= PromptBuilder.new
  end

  # Dipendenze per ImageService
  def self.image_validator
    @image_validator ||= ImageValidator.new
  end

  def self.image_generator
    @image_generator ||= ImageGenerator.new
  end

  def self.image_storage
    @image_storage ||= ImageStorage.new
  end

  # Metodo per resettare tutte le istanze (utile per test)
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