require "aws-sdk-bedrockruntime"
require "json"

class AiService
  def initialize
    # Client AWS Bedrock: usa le credenziali in ambiente (anche session token SSO) e la regione
    @client = Aws::BedrockRuntime::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      session_token: ENV["AWS_SESSION_TOKEN"],
      region: ENV["AWS_REGION"] || "us-east-1"
    )
  end

  # Genera un testo per una specifica azienda e tono
  def genera(testo_utente, company_id, nome_tono)
    # Recupera azienda e tono scelto (scoped per company)
    company = Company.find(company_id)
    tono_db = company.tones.find_by(name: nome_tono)

    # Se manca il tono, fallback a istruzioni generiche
    istruzioni_tono = tono_db&.instructions || "Rispondi in modo professionale."
    descrizione_azienda = company.description.presence || ""

    # Prompt di sistema semplificato e diretto
    system_prompt = <<~PROMPT.strip
      Stai scrivendo per conto di"#{company.name}".
      Descrizione: #{descrizione_azienda}
      Usando un tono: #{istruzioni_tono}

      Rispondi SOLO con il contenuto richiesto, senza prefissi, etichette, dialoghi o conversazioni, pronto per essere usato direttamente.
      Non scrivere "Assistente:", "Bot:", tag XML o simili, e non lasciare contenuti incompleti o dentro parentesi quadre.
      Se serve usa il nome dell'azienda nel testo.
    PROMPT

    payload = {
      inputText: system_prompt + "\n\nRichiesta: #{testo_utente}",
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
    json_response["results"][0]["outputText"]
    # perché la risposta di Claude (via Bedrock) arriva come JSON con questa struttura:
    # content: array di blocchi restituiti dal modello (può contenere più parti).
    # [0]: prendiamo il primo blocco (il testo principale generato).
    # ["text"]: dentro quel blocco, il campo text è la stringa generata.
  end
end
