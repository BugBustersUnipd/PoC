# ConversationManager - Gestione CRUD di conversazioni e messaggi
#
# Servizio semplice per operazioni database su Conversation e Message.
# Non contiene business logic complessa, solo operazioni ActiveRecord.
#
# - Isola logica persistence dal resto dell'applicazione
# - Fornisce API chiara per gestione conversazioni
#
# Limite contestuale: mantiene solo ultimi 10 messaggi per performance
# (conversazioni lunghe causerebbero token limit su Bedrock)
class ConversationManager
  # Costante Ruby: MAIUSCOLO con underscore
  # Limite messaggi storico da recuperare per context window
  # Bedrock ha limite ~100k token, 10 messaggi è compromesso ragionevole
  # (ogni messaggio ~500-1000 token in media)
  MAX_CONTEXT_MESSAGES = 10

  # Recupera conversazione esistente o ne crea una nuova con tono associato
  #
  # Logica:
  # - Se conversation_id fornito: cerca nella collezione company.conversations (ignora tone)
  # - Se nil/assente: crea nuova conversazione e assegna il tone fornito (OBBLIGATORIO)
  #
  # company.conversations = associazione ActiveRecord (has_many in Company model)
  # .find(id) lancia ActiveRecord::RecordNotFound se ID non esiste
  # .create! lancia eccezione se validazioni falliscono (! = bang method)
  
  def fetch_or_create_conversation(company, conversation_id, tone)
    
    return company.conversations.find(conversation_id) if conversation_id.present?
    
    # Se arriviamo qui, conversation_id era nil/blank
    # create! crea nuovo record nel DB immediatamente
    # tone: OBBLIGATORIO, non può essere nil
    # Se tone è nil, lancia ActiveRecord::RecordInvalid
    company.conversations.create!(tone: tone)
  end

  # Salva coppia di messaggi user/assistant nel DB
  #
  # Crea due record Message associati alla conversazione:
  # 1. Messaggio utente (role: "user")
  # 2. Risposta assistente IA (role: "assistant")
  def save_messages(conversation, user_text, assistant_text)
    # Salva messaggio utente
    conversation.messages.create!(role: "user", content: user_text)
    
    # Salva risposta assistant (valore di ritorno implicito)
    conversation.messages.create!(role: "assistant", content: assistant_text)
  end

  # Recupera ultimi N messaggi della conversazione per context window
  #
  # Bedrock necessita storico conversazione per mantenere contesto
  def get_context_messages(conversation)
    conversation.messages.order(:created_at).last(MAX_CONTEXT_MESSAGES)
  end
end