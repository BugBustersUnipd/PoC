# Serializza toni comunicativi per un'azienda
class ToneSerializer
  # Ritorna company + array di toni (id, name, instructions)
  def self.serialize_collection(company, tones)
    {
      company: { id: company.id, name: company.name },
      tones: tones.map do |tone|
        {
          id: tone.id,
          name: tone.name,                    # es: "Formale", "Amichevole"
          instructions: tone.instructions     # prompt per guidare AI
        }
      end
    }
  end
end
