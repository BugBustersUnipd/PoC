# ConversationSerializer - Formattazione JSON per risposte API conversazioni
#
# Tre metodi con granularitá differenti:
# 1. serialize: singola conversazione con messaggi completi (dettaglio)
# 2. serialize_list: array conversazioni senza messaggi (lista)
# 3. serialize_search_results: risultati ricerca con total count
#
# Pattern: Serializer con granularitá multipla
# - Lista: meno dati (performance), solo metadati conversazione
# - Dettaglio: dati completi inclusi messaggi nested
# - Search: metadati + total per paginazione
class ConversationSerializer
  # Serializza conversazione singola con messaggi completi
  #
  # Usato per GET /conversations/:id (dettaglio conversazione)
  # Include array messaggi ordinati cronologicamente.
  #
  # @param conversation [Conversation] record con messaggi eager-loaded
  #
  # @return [Hash] JSON structure con messaggi nested:
  #   {
  #     id: 123,
  #     company_id: 1,
  #     created_at: \"2024-01-15T10:00:00Z\",
  #     updated_at: \"2024-01-15T11:30:00Z\",
  #     messages: [
  #       {id: 1, role: \"user\", content: \"Scrivi email\", created_at: \"...\"},
  #       {id: 2, role: \"assistant\", content: \"Gentile...\", created_at: \"...\"}
  #     ]
  #   }
  #
  # Nota performance:
  #   Usa .includes(:messages) in controller per evitare N+1 queries
  def self.serialize(conversation)
    {
      id: conversation.id,
      company_id: conversation.company_id,
      created_at: conversation.created_at.iso8601,
      updated_at: conversation.updated_at.iso8601,
      
      # .order(:created_at) = ordina messaggi cronologicamente (vecchio → nuovo)
      # .map = trasforma ogni Message in Hash
      # do |msg| ... end = block Ruby multi-line (equivalente { |msg| ... })
      messages: conversation.messages.order(:created_at).map do |msg|
        {
          id: msg.id,
          role: msg.role,  # \"user\" o \"assistant\"
          content: msg.content,  # Testo messaggio
          created_at: msg.created_at.iso8601
        }
      end
    }
  end

  # Serializza array di conversazioni senza messaggi
  #
  # Usato per GET /conversations (lista conversazioni)
  # Omette messages per performance (lista pu\u00f2 avere 50+ conversazioni).
  #
  # @param conversations [Array<Conversation>] array di record
  #
  # @return [Array<Hash>] array JSON structures:
  #   [
  #     {id: 1, title: \"Email\", created_at: \"...\", updated_at: \"...\", summary: \"...\"},
  #     {id: 2, title: \"SMS\", created_at: \"...\", updated_at: \"...\", summary: \"...\"}
  #   ]
  #
  # Frontend usa questa lista per:
  # - Mostrare lista con conversazioni recenti
  # - Click su conversazione → GET /conversations/:id per dettagli
  def self.serialize_list(conversations)
    # .map trasforma ogni Conversation in Hash
    # Block single-line con {}
    conversations.map do |c|
      {
        id: c.id,
        title: c.title,
        created_at: c.created_at.iso8601,
        updated_at: c.updated_at.iso8601,
        summary: c.summary
        # Nota: messages omessi intenzionalmente (performance)
      }
    end
  end

  # Serializza risultati ricerca con total count
  #
  # Usato per GET /conversations/search
  # Include total per frontend (\"Trovati X risultati\")
  #
  # @param conversations [Array<Conversation>] array risultati search
  #
  # @return [Hash] JSON structure con total + conversations:
  #   {
  #     total: 3,
  #     conversations: [
  #       {id: 1, title: \"Email\", summary: \"...\", updated_at: \"...\"},
  #       {id: 2, title: \"SMS\", summary: \"...\", updated_at: \"...\"}
  #     ]
  #   }
  def self.serialize_search_results(conversations)
    {
      # .size = count elementi array (senza query DB se array gi\u00e0 caricato)
      total: conversations.size,
      
      # Map risultati in formato compatto (no created_at, solo updated_at)
      conversations: conversations.map do |c|
        {
          id: c.id,
          title: c.title,
          summary: c.summary,
          updated_at: c.updated_at.iso8601
        }
      end
    }
  end
end
