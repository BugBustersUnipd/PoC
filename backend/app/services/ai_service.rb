require "aws-sdk-bedrockruntime"
require "json"

# AiService
# - Fornisce un'interfaccia semplice per generare testo con Amazon Bedrock usando l'API "Converse".
# - Gestisce lo storico conversazionale in modo sicuro (formato richiesto da Bedrock),
#   seleziona il modello (default: Amazon Nova Lite) e applica un fallback opzionale.
# - Mantiene le API e la struttura del servizio semplici per l'uso dai controller.
class AiService
  def initialize(text_generator:, conversation_manager:, prompt_builder:)
    @text_generator = text_generator
    @conversation_manager = conversation_manager
    @prompt_builder = prompt_builder
  end

  # Genera il testo usando Amazon Bedrock (API Converse)
  # Parametri:
  # - testo_utente: Stringa con la richiesta dell'utente
  # - company_id: ID dell'azienda (per contesto e persistenza conversazione)
  # - nome_tono: Nome del tono salvato su DB (istruzioni addizionali)
  # - conversation_id: ID conversazione esistente (opzionale) per mantenere il contesto
  # Ritorna: Hash con chiavi :text e :conversation_id
  def genera(testo_utente, company_id, nome_tono, conversation_id: nil)
    company = Company.find(company_id)
    conversation = @conversation_manager.fetch_or_create_conversation(company, conversation_id)

    tono_db = company.tones.find_by(name: nome_tono)
    istruzioni_tono = tono_db&.instructions.presence || "Rispondi in modo professionale."
    descrizione_azienda = company.description.presence || ""

    system_prompt = @prompt_builder.build_system_prompt(company.name, descrizione_azienda, istruzioni_tono)

    # Preleva lo storico della conversazione
    context_messages = @conversation_manager.get_context_messages(conversation)

    # Normalizza/normalizza i messaggi per la Converse API
    messages = @prompt_builder.normalize_messages(context_messages, testo_utente)

    output_text = @text_generator.generate_text(messages, system_prompt)

    # Persistenza dei messaggi
    @conversation_manager.save_messages(conversation, testo_utente, output_text)

    { text: output_text, conversation_id: conversation.id }
  end
end
