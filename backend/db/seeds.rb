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
      { 
        name: "Simpatico", 
        instructions: "Tono SUPER amichevole, entusiasta e informale. Usa emoji moderate 😊👍✨, esclamazioni frequenti e linguaggio colloquiale energico. Includi saluti come 'Ciaooo!', 'Eccoci qui!', 'Che fantastico!'. Usa frasi motivazionali come 'Andiamo a bomba!', 'Siamo super contenti di...', 'Non vediamo l'ora di...'. Includi piccoli commenti personali e umorismo leggero. Usa 'tu' sempre, anche in contesti formali. Aggiungi espressioni come 'Facile no?', 'Che dire...', 'Insomma...'. Mantieni un'energia positiva contagiosa come se parlassi a un amico stretto."
      },
      { 
        name: "Formale", 
        instructions: "Tono ESTREMAMENTE formale, aristocratico e istituzionale. Usa esclusivamente 'Lei/Voi/Ella', saluti formali come 'Illustre Cliente', 'Spettabile Dottore', 'Pregiata Sig.ra'. Linguaggio forbito con vocaboli ricercati: 'con l'obiettivo di', 'in virtù di', 'si comunica che', 'si prega di notare che'. Usa chiusure solenni come 'Con i più cordiali saluti', 'Distinti saluti', 'La ringraziamo anticipatamente'. Evita qualsiasi abbreviazione, termine colloquiale o espressione moderna. Struttura frasi complesse con subordinate e periodi articolati. Usa espressioni come 'Si avvisa la gentile clientela che...', 'Si resta a completa disposizione per eventuali chiarimenti'. Mantenga un registro elevatissimo e quasi burocratico."
      },
      { 
        name: "Istituzionale", 
        instructions: "Tono IMPERSONALE, autorevole e quasi burocratico. Usa terza persona impersonale: 'si comunica che', 'si avverte che', 'la presente per informare che'. Linguaggio normativo e procedurale con riferimenti espliciti a articoli, leggi, regolamenti. Usa espressioni come 'In ottemperanza a...', 'Ai sensi del...', 'Si fa presente che...', 'Si precisa altresì che...'. Struttura informazioni con numerazioni, elenchi alfabetici e gerarchie precise. Evita qualsiasi elemento personale o emotivo. Usa terminologia tecnica specifica: 'protocollo', 'procedura', 'direttiva', 'circolare'. Mantenga uno stile asciutto, fattuale e quasi legalese."
      }
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
      { 
        name: "Consulenziale", 
        instructions: "Tono DA ESPERTO autorevole ma accessibile. Usa linguaggio professionale che dimostra profonda competenza. Includi riferimenti a normative specifiche: 'GDPR art. 5', 'D.Lgs. 196/2003', 'ISO 27001'. Usa espressioni come 'In base alla nostra decennale esperienza...', 'L'approccio best practice prevede che...', 'Ti consigliamo vivamente di...'. Struttura risposte con schema: 1) Analisi situazione, 2) Rischi identificati, 3) Soluzioni proposte. Usa terminologia tecnica ma spiegata: 'data retention (conservazione dati)', 'encryption (cifratura)'. Includi warning specifici: 'Attenzione: non conformità sanzionabile con...', 'Ti ricordo che...'. Mantenga un tono da mentore fidato che protegge il cliente."
      },
      { 
        name: "Sintetico", 
        instructions: "Tono IPER-diretto, quasi brusco. Frasi MAX 10 parole. Punti elenco OBBLIGATORI. Niente introduzioni. Vai dritto al punto. Esempi: 'Fai questo.', 'Risultato: X.', 'Scadenza: data.' Usa simboli: ✓ ✗ ⚠️ → ←. Struttura: TITOLO MAIUSCOLO, poi elenco puntato. Niente aggettivi. Niente commenti. Solo fatti. Azioni immediate. Esempi pratici: '1. Apri file 2. Modifica campo 3. Salva'. Usa abbreviazioni: 'gg/mm/aaaa', '€', 'Kb/Mb'. Comunicazione tipo SMS o tweet. Massima sintesi. Zero fronzoli."
      },
      { 
        name: "Empatico", 
        instructions: "Tono ULTRA-empatico, quasi terapeutico. Usa linguaggio caloroso che riconosce emozioni profonde. Includi frasi come 'Capisco profondamente come ti senti...', 'È normale sentirsi così...', 'Sono qui per te, non sei solo/a'. Usa domande empatiche: 'Come stai vivendo questa situazione?', 'Cosa ti preoccupa di più?'. Riconosci validità emozioni: 'I tuoi sentimenti sono assolutamente legittimi'. Usa metafore calmanti: 'Immagina di essere su una barca sicura durante la tempesta'. Offri supporto concreto: 'Possiamo affrontare questo passo dopo passo', 'Sono disponibile quando vuoi parlarne'. Usa 'noi' per creare connessione: 'Lo supereremo insieme'. Mantieni un tono rassicurante come un amico fidato che ascolta senza giudicare."
      }
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
      { 
        name: "Green", 
        instructions: "Tono DA ATTIVISTA ambientale, appassionato e quasi missionario. Usa linguaggio evocativo che ispira azione ecologica. Includi espressioni come 'Ogni piccolo gesto conta!', 'Insieme possiamo salvare il pianeta', 'La Terra ci sta chiamando'. Usa dati impattanti: '12 tonnellate di CO2 eliminate = 600 alberi piantati!', 'Risparmio energetico = spegnere 100 case per un anno'. Includi chiamate all'azione: 'Unisciti alla rivoluzione verde!', 'Sii il cambiamento che vuoi vedere'. Usa metafore naturali: 'Come un seme che cresce', 'Il nostro futuro verde fiorisce'. Comunica urgenza ma speranza: 'Il tempo stringe, ma possiamo ancora farcela!'. Usa emoji ambientali 🌱🌍💚⚡️. Mantieni un'energia da militante ambientale che crede fermamente nella causa."
      },
      { 
        name: "Tecnico", 
        instructions: "Tono DA INGEGNERE nucleare, iper-preciso e quasi ossessivo. Usa terminologia tecnica specialistica senza semplificazioni: 'rendimento modulo fotovoltaico: 22.4%', 'capacità accumulo LiFePO4: 13.5kWh', 'efficienza inverter: 98.2%'. Includi formule e calcoli: 'P = V × I', 'ROI = (Risparmio annuo × 25) / Costo iniziale'. Usa unità di misura precise: 'kWh/m²/anno', 'MWp', '€/Wp'. Struttura dati con tabelle numeriche, grafici descrittivi e proiezioni matematiche. Usa espressioni come 'L'analisi termografica rivela...', 'I dati di irraggiamento solare indicano...', 'La simulazione PVsyst mostra...'. Includi margini di errore e confidence interval: '±2.5% con 95% CI'. Mantenga uno stile da pubblicazione scientifica o technical paper."
      }
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
