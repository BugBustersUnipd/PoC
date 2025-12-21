require "aws-sdk-bedrockruntime"
require "json"

class AiService
  MAX_CONTEXT_MESSAGES = 8

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
    context_block = build_context_block(context_messages)

    payload = {
      inputText: [system_prompt, context_block, "Nuova richiesta: #{testo_utente}"].reject(&:empty?).join("\n\n"),
      textGenerationConfig: {
        maxTokenCount: 500,
        temperature: 0.4
      }
    }

    response = @client.invoke_model({
      model_id: "amazon.titan-text-express-v1",
      body: payload.to_json,
      content_type: "application/json",
      accept: "application/json"
    })

    json_response = JSON.parse(response.body.string)
    output_text = json_response["results"][0]["outputText"]

    # Persistiamo la conversazione: prima il prompt utente, poi la risposta
    conversation.messages.create!(role: "user", content: testo_utente)
    conversation.messages.create!(role: "assistant", content: output_text)

    [output_text, conversation]
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
    return "" if messages.empty?

    body = messages.map { |msg| "#{msg.role.capitalize}: #{msg.content}" }.join("\n")
    "Storico conversazione (più recente in fondo):\n#{body}"
  end

  def fetch_or_create_conversation(company, conversation_id)
    return company.conversations.find(conversation_id) if conversation_id.present?

    company.conversations.create!
  end
end
