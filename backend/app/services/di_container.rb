# Dependency Injection Container
# Contenitore semplice per gestire le dipendenze dell'applicazione
# Rispetta DIP fornendo astrazioni invece di implementazioni concrete

class DIContainer
  def self.ai_service
    @ai_service ||= AiService.new
  end

  def self.image_service
    @image_service ||= ImageService.new
  end

  # Metodo per resettare le istanze (utile per test)
  def self.reset!
    @ai_service = nil
    @image_service = nil
  end
end