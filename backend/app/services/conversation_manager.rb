# ConversationManager - Gestione CRUD di conversazioni e messaggi
#
# Servizio semplice per operazioni database su Conversation e Message.
# Non contiene business logic complessa, solo operazioni ActiveRecord.
#
# Pattern: Repository-like Service
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
  #
  # @param company [Company] record Company ActiveRecord
  # @param conversation_id [Integer, nil] ID conversazione esistente (optional)
  # @param tone [Tone] record Tone da assegnare a nuova conversazione (OBBLIGATORIO se conversation_id assente)
  #
  # @return [Conversation] record conversazione (esistente o appena creato)
  #
  # @raise [ActiveRecord::RecordNotFound] se conversation_id non trovato
  # @raise [ActiveRecord::RecordInvalid] se tone è nil e conversation_id assente (tone obbligatorio)
  #
  # Esempio:
  #   # Nuova conversazione con tono (obbligatorio)
  #   tone = company.tones.find_by(name: "formale")
  #   conv = manager.fetch_or_create_conversation(company, nil, tone)
  #   # => #<Conversation id: 123, company_id: 1, tone_id: 5, created_at: ...>
  #
  #   # Conversazione esistente (tone ignorato)
  #   conv = manager.fetch_or_create_conversation(company, 123, tone)
  #   # => #<Conversation id: 123, tone_id: 2, ...>  # tone_id originale, non cambia
  def fetch_or_create_conversation(company, conversation_id, tone)
    # .present? = opposto di .blank?, ritorna true se valore non è nil/empty
    # return = uscita early dalla funzione (guard clause pattern)
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
  #
  # conversation.messages = associazione ActiveRecord (has_many in Conversation)
  # .create! crea record nel DB e lancia eccezione se validazioni falliscono
  #
  # @param conversation [Conversation] conversazione a cui aggiungere messaggi
  # @param user_text [String] testo messaggio utente
  # @param assistant_text [String] testo risposta IA
  #
  # @return [Message] ultimo Message creato (assistant)
  #
  # @raise [ActiveRecord::RecordInvalid] se validazioni Message falliscono
  #
  # Esempio:
  #   manager.save_messages(
  #     conversation,
  #     "Scrivi email di benvenuto",
  #     "Gentile cliente, benvenuto..."
  #   )
  def save_messages(conversation, user_text, assistant_text)
    # Salva messaggio utente
    conversation.messages.create!(role: "user", content: user_text)
    
    # Salva risposta assistant (valore di ritorno implicito)
    conversation.messages.create!(role: "assistant", content: assistant_text)
  end

  # Recupera ultimi N messaggi della conversazione per context window
  #
  # Bedrock necessita storico conversazione per mantenere contesto,
  # ma c'è limite token (~100k). Soluzione: solo ultimi 10 messaggi.
  #
  # .order(:created_at) ordina per timestamp crescente (più vecchio prima)
  # .last(N) prende ultimi N elementi (più recenti)
  #
  # Perché order + last invece di order(desc).limit?
  # - last(N) ritorna array nell'ordine originale (vecchio -> nuovo)
  # - order(desc).limit ritorna ordine inverso (nuovo -> vecchio)
  # - Bedrock vuole messaggi cronologici vecchio->nuovo
  #
  # @param conversation [Conversation] conversazione da cui recuperare storico
  #
  # @return [Array<Message>] ultimi 10 messaggi ordinati cronologicamente
  #
  # Esempio:
  #   messages = manager.get_context_messages(conversation)
  #   # => [<Message "Ciao">, <Message "Salve">, ...] (max 10)
  def get_context_messages(conversation)
    # conversation.messages = ActiveRecord::Relation (query lazy)
    # order + last triggera SQL: ORDER BY created_at ASC LIMIT 10
    conversation.messages.order(:created_at).last(MAX_CONTEXT_MESSAGES)
  end
end