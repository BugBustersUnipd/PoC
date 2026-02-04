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
  # Logica tono:
  # - Se conversation_id ASSENTE (nuova chat): nome_tono è OBBLIGATORIO
  #   → Crea conversazione con quel tono e lo salva nel DB
  # - Se conversation_id PRESENTE (continua chat): nome_tono non va messo, da errore se fornito
  #   → Usa il tono già salvato nella conversazione precedente
  #
  # @param testo_utente [String] richiesta dell'utente (es. "Scrivi email di benvenuto")
  # @param company_id [Integer] ID azienda per contesto e ownership
  # @param nome_tono [String, nil] nome tono salvato su DB (es. "formale", "amichevole")
  #   - OBBLIGATORIO se conversation_id è nil
  #   - ERRORE se conversation_id è presente e nome_tono è fornito
  # @param conversation_id [Integer, nil] ID conversazione esistente (nil = nuova conversazione)
  #
  # @return [Hash] { text: "risposta AI", conversation_id: 123 }
  #
  # @raise [ActiveRecord::RecordNotFound] se company_id non esiste
  # @raise [ActiveRecord::RecordNotFound] se conversation_id non esiste
  #
  # Esempio - Nuova conversazione:
  #   result = ai_service.genera(
  #     "Scrivi email di benvenuto",
  #     company_id: 1,
  #     nome_tono: "formale",
  #     conversation_id: nil  # Nuova chat
  #   )
  #   # => conversation creata con tone salvato
  #
  # Esempio - Continua conversazione:
  #   result = ai_service.genera(
  #     "Modifica il tono",
  #     company_id: 1,
  #     nome_tono: nil,  # Ignorato!
  #     conversation_id: 42  # Usa tono dalla chat precedente
  #   )
  #   # => usa conversation.tone (quello originale)
  def genera(testo_utente, company_id, nome_tono, conversation_id: nil)
    # find lancia eccezione se non trova (vs find_by che ritorna nil)
    # Questo blocca immediatamente richieste con company_id invalido
    company = Company.find(company_id)
    
    # Carica tono comunicativo dal DB (es. "formale", "amichevole")
    # Questo viene fatto PRIMA di fetch_or_create per passarlo al manager
    tono_db = company.tones.find_by(name: nome_tono) if nome_tono.present?
    
    # Recupera conversazione esistente o ne crea una nuova con il tono
    # Se conversation_id presente: ignora tono_db (usa quello salvo nella chat)
    # Se conversation_id nil: salva tono_db nella nuova conversazione
    conversation = @conversation_manager.fetch_or_create_conversation(company, conversation_id, tono_db)

    # Determina quale tono usare:
    # - Se conversazione ha tono: usalo (conversation.tone precedente oppure appena salvato)
    # - Se conversazione non ha tono: fallback a istruzioni generiche
    tono_da_usare = conversation.tone
    
    # &.instructions accede a instructions solo se tono_da_usare non è nil (evita NoMethodError)
    # .presence ritorna il valore se non blank, altrimenti nil
    # || "..." fornisce default se tono manca
    istruzioni_tono = tono_da_usare&.instructions.presence || "Rispondi in modo professionale."
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
