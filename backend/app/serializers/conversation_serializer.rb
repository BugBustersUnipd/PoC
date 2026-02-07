# Serializza conversazioni con tre livelli di dettaglio
class ConversationSerializer
  # Conversazione completa con messaggi (per dettaglio)
  def self.serialize(conversation)
    {
      id: conversation.id,
      company_id: conversation.company_id,
      created_at: conversation.created_at.iso8601,
      updated_at: conversation.updated_at.iso8601,
      messages: conversation.messages.order(:created_at).map do |msg|
        {
          id: msg.id,
          role: msg.role,              # "user" o "assistant"
          content: msg.content,
          created_at: msg.created_at.iso8601
        }
      end
    }
  end

  # Lista conversazioni senza messaggi (per performance)
  def self.serialize_list(conversations)
    conversations.map do |c|
      {
        id: c.id,
        title: c.title,
        created_at: c.created_at.iso8601,
        updated_at: c.updated_at.iso8601,
        summary: c.summary
      }
    end
  end

  # Risultati ricerca con conteggio totale
  def self.serialize_search_results(conversations)
    {
      total: conversations.size,
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
