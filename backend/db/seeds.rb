# Pulizia database
Message.delete_all
Conversation.delete_all
Document.delete_all
GeneratedImage.delete_all
Tone.delete_all
Company.delete_all

companies_data = [
  {
    name: "Acme Corporation",
    description: "Suite B2B per gestione progetti e collaborazione",
    tones: [
      {
        name: "Simpatico",
        instructions: "Tono amichevole, entusiasta e informale. Usa emoji moderate, esclamazioni frequenti e linguaggio colloquiale. Crea connessione emotiva positiva."
      },
      {
        name: "Formale",
        instructions: "Tono estremamente formale e professionale. Usa Lei, saluti formali e linguaggio forbito. Mantieni massima correttezza."
      },
      {
        name: "Istituzionale",
        instructions: "Tono impersonale e autorevole. Usa terza persona e linguaggio normativo. Comunica con autorità burocratica."
      }
    ],
    conversations: [
      {
        title: "Lancio Suite B2B",
        messages: [
          { role: "user", content: "Come possiamo comunicare il lancio della suite ai clienti?" },
          { role: "assistant", content: "Abbiamo preparato una campagna integrata con email, social media e webinar." },
          { role: "user", content: "Quali sono i messaggi chiave?" },
          { role: "assistant", content: "Semplicità, integrazione, produttività. Questi i tre pilastri della comunicazione." }
        ]
      },
      {
        title: "Feedback utenti Beta",
        messages: [
          { role: "user", content: "Cosa dicono gli utenti beta della suite?" },
          { role: "assistant", content: "I feedback sono molto positivi. Apprezzano l'interfaccia intuitiva e le integrazioni." }
        ]
      }
    ]
  },
  {
    name: "Nexum Studio",
    description: "Consulenza legale e HR specializzata in tech",
    tones: [
      {
        name: "Consulenziale",
        instructions: "Tono da esperto autorevole ma accessibile. Cita normative specifiche e best practice. Struttura risposte in analisi, rischi e soluzioni."
      },
      {
        name: "Sintetico",
        instructions: "Tono iper-diretto e conciso. Frasi brevissime. Usa elenchi puntati. Solo fatti, nessun commento superfluo."
      },
      {
        name: "Empatico",
        instructions: "Tono caloroso e supportivo. Riconosci emozioni e incertezze. Comunica supporto concreto e stai vicino al cliente."
      }
    ],
    conversations: [
      {
        title: "Onboarding GDPR Compliance",
        messages: [
          { role: "user", content: "Come mettiamo la nostra startup in compliance GDPR?" },
          { role: "assistant", content: "Servono 4 pilastri: data governance, privacy policy, consent management, data protection impact assessment." },
          { role: "user", content: "Da dove iniziamo?" },
          { role: "assistant", content: "Data audit, poi documentazione, quindi implementazione tecnica." }
        ]
      },
      {
        title: "Gestione Contratti Tech",
        messages: [
          { role: "user", content: "Come proteggiamo la nostra proprietà intellettuale nei contratti?" },
          { role: "assistant", content: "IP ownership, non-compete, indemnification clauses. Posso mostrarvi template certificati." }
        ]
      },
      {
        title: "HR Policy Aziendale",
        messages: [
          { role: "user", content: "Abbiamo bisogno di una policy per il remote working" },
          { role: "assistant", content: "Prepareremo un documento completo con linee guida, tools autorizzati e security requirements." }
        ]
      }
    ]
  },
  {
    name: "GreenWave Energy",
    description: "Provider di energie rinnovabili e sostenibilità",
    tones: [
      {
        name: "Ambientalista",
        instructions: "Tono passionato e ispirante. Comunica urgenza climatica ma con speranza. Usa dati concreti di impatto ambientale."
      },
      {
        name: "Tecnico",
        instructions: "Tono da ingegnere. Preciso, numerico. Includi formule, efficienze, calcoli ROI. Comunica con rigore scientifico."
      }
    ],
    conversations: [
      {
        title: "Transizione Energia Verde",
        messages: [
          { role: "user", content: "Cosa possiamo fare per ridurre impronta carbonica?" },
          { role: "assistant", content: "Audit energetico, then solar investment, storage battery, grid integration strategy." },
          { role: "user", content: "Qual è il ROI previsto?" },
          { role: "assistant", content: "Payback period 5-7 anni, poi risparmio puro. Stimato 40% riduzione consumi." }
        ]
      },
      {
        title: "Progetto Fotovoltaico PMI",
        messages: [
          { role: "user", content: "Vorremmo un impianto fotovoltaico per la nostra fabbrica" },
          { role: "assistant", content: "Valuteremo irraggiamento solare, superficie disponibile, load profile e dimensioneremo sistema." }
        ]
      }
    ]
  },
  {
    name: "DataViz Analytics",
    description: "Piattaforma di business intelligence e visualizzazione dati",
    tones: [
      {
        name: "Data-driven",
        instructions: "Tono analitico e basato su numeri. Usa insights, metriche, KPI. Comunica valore attraverso dati concreti."
      },
      {
        name: "Divulgativo",
        instructions: "Tono accessibile e educativo. Spiega concetti complessi in modo semplice. Usa esempi pratici e analogie."
      }
    ],
    conversations: [
      {
        title: "Dashboard Executive",
        messages: [
          { role: "user", content: "Come creiamo dashboard utili per il C-level?" },
          { role: "assistant", content: "KPI essenziali, trend, comparativi. 5-7 metriche max. Real-time quando possibile." }
        ]
      }
    ]
  }
]

companies_data.each do |company_data|
  company = Company.create!(
    name: company_data[:name],
    description: company_data[:description]
  )

  # Creazione toni
  company_data[:tones].each do |tone_data|
    company.tones.create!(tone_data)
  end

  # Creazione conversazioni e messaggi
  company_data[:conversations].each_with_index do |conversation_data, idx|
    # Usa il primo tono disponibile (o cicla tra i toni)
    tone = company.tones[idx % company.tones.count]
    conversation = Conversation.create!(
      company_id: company.id,
      tone_id: tone.id,
      title: conversation_data[:title]
    )
    conversation_data[:messages].each do |message_data|
      conversation.messages.create!(message_data)
    end
  end
end

puts "\n✓ SEED COMPLETATO"
puts "  • #{Company.count} aziende create"
puts "  • #{Tone.count} toni configurati"
puts "  • #{Conversation.count} conversazioni di esempio"
puts "  • #{Message.count} messaggi di test"
