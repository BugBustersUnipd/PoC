# TextGenerationSerializer - Formattazione JSON per risposte API generazione testo
#
# Serializer minimale per endpoint text_generation.
# Ritorna solo testo generato + ID conversazione per context continuity.
#
# Pattern: Serializer con responsabilità singola
# - Solo 2 campi: massima semplicità
# - Frontend può usare conversation_id per prossima richiesta
class TextGenerationSerializer
  # Serializza risposta generazione testo
  #
  # Metodo di classe (vedi GeneratedImageSerializer per spiegazione self.)
  #
  # @param text [String] testo generato da Bedrock
  # @param conversation_id [Integer] ID conversazione per context
  #
  # @return [Hash] JSON structure:
  #   {text: "...", conversation_id: 123}
  #
  # Esempio:
  #   TextGenerationSerializer.serialize(
  #     text: "Gentile cliente, benvenuto...",
  #     conversation_id: 45
  #   )
  #   # => {text: "Gentile cliente...", conversation_id: 45}
  #
  # Frontend usa conversation_id per:
  #   POST /text_generation {conversation_id: 45, text: "modifica il tono"}
  def self.serialize(text:, conversation_id:)
    {
      text: text,  # Testo generato dall'IA
      conversation_id: conversation_id  # ID per continuare conversazione
    }
  end
end
