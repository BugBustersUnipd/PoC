# Serializza risposta generazione testo
class TextGenerationSerializer
  # Ritorna testo generato + conversation_id per continuare il context
  def self.serialize(text:, conversation_id:)
    {
      text: text,
      conversation_id: conversation_id
    }
  end
end
