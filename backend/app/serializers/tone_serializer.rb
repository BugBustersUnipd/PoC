# ToneSerializer - Formattazione JSON per risposte API toni comunicativi
#
# Serializza company + toni associati in struttura nested.
# Usato per GET /companies/:id/tones

class ToneSerializer
  # Serializza company + array di toni
  #
  # @param company [Company] azienda proprietaria toni
  # @param tones [Array<Tone>] array toni associati
  #
  # @return [Hash] JSON structure nested:
  #   {
  #     company: {id: 1, name: "Acme Corp"},
  #     tones: [
  #       {id: 1, name: "Formale", instructions: "Usa linguaggio professionale..."},
  #       {id: 2, name: "Amichevole", instructions: "Tono cordiale e informale..."}
  #     ]
  #   }
  #
  # Esempio uso frontend:
  #   fetch('/companies/1/tones')
  #     .then(res => res.json())
  #     .then(data => {
  #       console.log(data.company.name);  // "Acme Corp"
  #       console.log(data.tones.length);  // 2
  #     })
  def self.serialize_collection(company, tones)
    {
      # Company parent: solo id + name (info minime)
      company: { id: company.id, name: company.name },
      
      # Tones array: trasforma ogni Tone in Hash
      # .map + do...end = block multi-line per leggibilità
      tones: tones.map do |tone|
        {
          id: tone.id,
          
          # name: nome tono visualizzato in UI ("Formale", "Amichevole")
          name: tone.name,
          
          # instructions: prompt parziale per Bedrock system prompt
          # Esempio: "Usa linguaggio tecnico ma accessibile, evita gerghi"
          instructions: tone.instructions
        }
      end
    }
  end
end
