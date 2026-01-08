class ConversationManager
  MAX_CONTEXT_MESSAGES = 10

  def fetch_or_create_conversation(company, conversation_id)
    return company.conversations.find(conversation_id) if conversation_id.present?
    company.conversations.create!
  end

  def save_messages(conversation, user_text, assistant_text)
    conversation.messages.create!(role: "user", content: user_text)
    conversation.messages.create!(role: "assistant", content: assistant_text)
  end

  def get_context_messages(conversation)
    conversation.messages.order(:created_at).last(MAX_CONTEXT_MESSAGES)
  end
end