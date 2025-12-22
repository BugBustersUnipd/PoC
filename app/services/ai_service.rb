require "aws-sdk-bedrockruntime"
require "json"

class AiService
  MAX_CONTEXT_MESSAGES = 2

  def initialize
    # Client AWS Bedrock: usa le credenziali in ambiente (anche session token SSO) e la regione
    @client = Aws::BedrockRuntime::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"],
      region: ENV["AWS_REGION"] || "us-east-1"
    )
  end

  # Genera un testo per una specifica azienda e tono, mantenendo una conversazione opzionale
  def genera(testo_utente, company_id, nome_tono, conversation_id: nil)
    company = Company.find(company_id)
    conversation = fetch_or_create_conversation(company, conversation_id)

    tono_db = company.tones.find_by(name: nome_tono)
    istruzioni_tono = tono_db&.instructions || "Rispondi in modo professionale."
    descrizione_azienda = company.description.presence || ""

    system_prompt = build_system_prompt(company.name, descrizione_azienda, istruzioni_tono)
    context_messages = conversation.messages.order(:created_at).last(MAX_CONTEXT_MESSAGES)

    # Costruisci l'array di messaggi storici in formato nativo per l'API Converse
    messages = build_messages_array(context_messages, testo_utente)

    model_id = ENV["BEDROCK_MODEL_ID"].presence || "anthropic.claude-3-5-sonnet-20241022-v2:0"
    log_debug("Bedrock model_id: #{model_id}")

    # Chiama il modello Claude via AWS Bedrock con la conversazione nativa
    response = @client.converse({
      model_id: model_id,  # ID del modello Claude da usare
      messages: messages,  # Array di messaggi storici in formato nativo Bedrock
      system: [
        { text: system_prompt }  # Istruzioni di sistema con info azienda e tono
      ],
      inference_config: {
        max_tokens: 500,  # Massimo 500 token nella risposta
        temperature: 0.2  # Bassa temperatura per risposte deterministiche e coerenti
      }
    })

    output_text = response.output.message.content[0].text

    # Persistiamo la conversazione: prima il prompt utente, poi la risposta
    conversation.messages.create!(role: "user", content: testo_utente)
    conversation.messages.create!(role: "assistant", content: output_text)

    { text: output_text, conversation_id: conversation.id }
  end

  private

  def build_system_prompt(nome_azienda, descrizione, istruzioni_tono)
    <<~PROMPT.strip
      Stai scrivendo per conto di "#{nome_azienda}".
      Descrizione: #{descrizione}
      Usando un tono: #{istruzioni_tono}

      Rispondi SOLO con il contenuto richiesto, senza prefissi, etichette, dialoghi o conversazioni, pronto per essere usato direttamente.
      Non scrivere "Assistente:", "Bot:", tag XML o simili, e non lasciare contenuti incompleti o dentro parentesi quadre.
      Se serve usa il nome dell'azienda nel testo.
    PROMPT
  end

  def build_context_block(messages)
    # Se non ci sono messaggi, ritorna una stringa vuota
    return "" if messages.empty?

    # Mappa ogni messaggio nel formato "Role: Content" e li unisce con newline
    body = messages.map { |msg| "#{msg.role.capitalize}: #{msg.content}" }.join("\n")
    # Ritorna il blocco di contesto con intestazione e i messaggi formattati
    "Storico conversazione (più recente in fondo):\n#{body}"
  end

  def build_messages_array(context_messages, testo_utente)
    # Converti i messaggi storici nel formato nativo di Bedrock Converse
    messages = context_messages.map { |msg|
      {
        role: msg.role,
        content: [ { text: msg.content } ]
      }
    }

    # Aggiungi il nuovo messaggio utente
    messages << {
      role: "user",
      content: [ { text: testo_utente } ]
    }

    messages
  end

  def fetch_or_create_conversation(company, conversation_id)
    return company.conversations.find(conversation_id) if conversation_id.present?

    company.conversations.create!
  end
end
