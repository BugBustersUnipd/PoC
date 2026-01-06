# Pulisce i dati esistenti (prima messaggi e conversazioni, poi toni e aziende)
Message.delete_all
Conversation.delete_all
Tone.delete_all
Company.delete_all

companies_data = [
  {
    name: "Acme",
    description: "Suite B2B",
    tones: [
      { name: "Simpatico", instructions: "Tono amichevole e leggero" },
      { name: "Formale", instructions: "Tono professionale e conciso" },
      { name: "Istituzionale", instructions: "Tono autorevole e preciso" }
    ],
    conversation: {
      title: "Esempio Acme",
      messages: [
        { role: "user", content: "Scrivi un breve post di prova per il lancio della suite." },
        { role: "assistant", content: "Ecco un breve post di prova per la suite B2B di Acme." }
      ]
    }
  },
  {
    name: "Nexum Studio",
    description: "Consulenza legale e HR",
    tones: [
      { name: "Consulenziale", instructions: "Tono chiaro, rassicurante e orientato alla compliance" },
      { name: "Sintetico", instructions: "Tono diretto con punti elenco essenziali" },
      { name: "Empatico", instructions: "Tono vicino al cliente, riconosce criticita e propone soluzioni" }
    ],
    conversation: {
      title: "Onboarding HR",
      messages: [
        { role: "user", content: "Prepara una mail di benvenuto per un nuovo dipendente con riferimenti a privacy e sicurezza." },
        { role: "assistant", content: "Benvenuto a bordo! Trovi in allegato la policy privacy, le linee guida sicurezza e i contatti HR per qualsiasi esigenza." }
      ]
    }
  },
  {
    name: "Helios Energia",
    description: "Provider energie rinnovabili",
    tones: [
      { name: "Green", instructions: "Tono focalizzato su sostenibilita e benefici ambientali" },
      { name: "Tecnico", instructions: "Tono con dati e KPI di produzione energetica" }
    ],
    conversation: {
      title: "Promo fotovoltaico",
      messages: [
        { role: "user", content: "Scrivi un messaggio promozionale per clienti PMI sul nuovo piano fotovoltaico." },
        { role: "assistant", content: "Con il piano fotovoltaico Helios riduci i costi fino al 30% e abbatti 12 tonnellate di CO2 l'anno." }
      ]
    }
  }
]

companies_data.each do |data|
  company = Company.create!(data.slice(:name, :description))

  Array(data[:tones]).each do |tone|
    company.tones.create!(tone)
  end

  conversation_data = data[:conversation]
  next unless conversation_data

  conversation = company.conversations.create!(title: conversation_data[:title])
  Array(conversation_data[:messages]).each do |message|
    conversation.messages.create!(message)
  end
end

puts "Seed completato: #{Company.count} aziende, #{Tone.count} toni, #{Conversation.count} conversazioni, #{Message.count} messaggi."
