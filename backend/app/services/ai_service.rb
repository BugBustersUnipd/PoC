require "aws-sdk-bedrockruntime"
require "json"

# AiService - Servizio orchestratore per generazione testo via Amazon Bedrock
#
# Questo servizio coordina l'intero flusso di generazione testo conversazionale:
# 1. Recupera/crea conversazione per mantenere contesto
# 2. Carica tono comunicativo dell'azienda dal DB
# 3. Costruisce system prompt personalizzato
# 4. Recupera storico messaggi precedenti (context)
# 5. Normalizza messaggi per API Bedrock Converse
# 6. Chiama AI per generare risposta
# 7. Salva scambio user/assistant nel DB
#
# Pattern utilizzato: Service Orchestrator
# - Non contiene logica di basso livello (API, DB, formattazione)
# - Delega a specialist objects (text_generator, conversation_manager, prompt_builder)
# - Facilita testing: puoi moccare ogni dipendenza
#
# Dipendenze iniettate:
# @param text_generator [AiTextGenerator] chiamate HTTP a Bedrock
# @param conversation_manager [ConversationManager] CRUD conversazioni/messaggi
# @param prompt_builder [PromptBuilder] costruzione prompt formattati
class AiService
  def initialize(text_generator:, conversation_manager:, prompt_builder:)
    @text_generator = text_generator
    @conversation_manager = conversation_manager
    @prompt_builder = prompt_builder
  end

  # Genera testo AI personalizzato per azienda con contesto conversazionale
  #
  # @param testo_utente [String] richiesta dell'utente (es. "Scrivi email di benvenuto")
  # @param company_id [Integer] ID azienda per contesto e ownership
  # @param nome_tono [String] nome tono salvato su DB (es. "formale", "amichevole")
  # @param conversation_id [Integer, nil] ID conversazione esistente (nil = nuova conversazione)
  #
  # @return [Hash] { text: "risposta AI", conversation_id: 123 }
  #
  # @raise [ActiveRecord::RecordNotFound] se company_id non esiste
  #
  # Esempio:
  #   result = ai_service.genera(
  #     "Scrivi email di benvenuto",
  #     company_id: 1,
  #     nome_tono: "formale",
  #     conversation_id: 42  # Continua conversazione esistente
  #   )
  #   puts result[:text]  # "Gentile Cliente, siamo lieti di darLe il benvenuto..."
  def genera(testo_utente, company_id, nome_tono, conversation_id: nil)
    # find lancia eccezione se non trova (vs find_by che ritorna nil)
    # Questo blocca immediatamente richieste con company_id invalido
    company = Company.find(company_id)
    
    # Recupera conversazione esistente o ne crea una nuova
    # Le conversazioni mantengono contesto tra multiple richieste
    conversation = @conversation_manager.fetch_or_create_conversation(company, conversation_id)

    # Carica tono comunicativo dal DB (es. "formale", "amichevole")
    # find_by ritorna nil se non trova, quindi usiamo safe navigation (&.)
    tono_db = company.tones.find_by(name: nome_tono)
    # &.instructions accede a instructions solo se tono_db non è nil (evita NoMethodError)
    # .presence ritorna il valore se non blank, altrimenti nil
    # || "..." fornisce default se tono non trovato o istruzioni vuote
    istruzioni_tono = tono_db&.instructions.presence || "Rispondi in modo professionale."
    descrizione_azienda = company.description.presence || ""

    # Costruisce system prompt personalizzato con contesto aziendale
    # Il system prompt dice all'AI "chi sei" e "come devi comportarti"
    system_prompt = @prompt_builder.build_system_prompt(company.name, descrizione_azienda, istruzioni_tono)

    # Recupera ultimi N messaggi della conversazione per contesto
    # Limita a MAX_CONTEXT_MESSAGES per evitare token limit Bedrock
    context_messages = @conversation_manager.get_context_messages(conversation)

    # Normalizza messaggi in formato richiesto da Bedrock Converse API
    # - Merge messaggi consecutivi stesso ruolo (Bedrock non li accetta)
    # - Assicura che inizi sempre con "user" (requisito API)
    # - Struttura: [{ role: "user", content: [{text: "..."}] }, ...]
    messages = @prompt_builder.normalize_messages(context_messages, testo_utente)

    # Chiamata effettiva all'AI (Bedrock Converse API)
    # Questo è il punto dove avviene la generazione vera e propria
    output_text = @text_generator.generate_text(messages, system_prompt)

    # Salva scambio user/assistant nel DB per future conversazioni
    # Crea 2 record Message: uno role="user", uno role="assistant"
    @conversation_manager.save_messages(conversation, testo_utente, output_text)

    # Ritorna risposta + ID conversazione per permettere follow-up
    { text: output_text, conversation_id: conversation.id }
  end
end
