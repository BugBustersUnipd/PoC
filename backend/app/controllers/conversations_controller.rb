class ConversationsController < ActionController::API
  # GET /conversazioni?company_id=:id
  def index
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    conversations = Conversation.where(company_id: company_id).order(updated_at: :desc).limit(50)
    render json: conversations.as_json(only: [ :id, :title, :created_at, :updated_at, :summary ])
  end

  # GET /conversazioni/:id
  def show
    conversation = Conversation.includes(:messages).find(params[:id])

    if params[:company_id].present? && conversation.company_id.to_s != params[:company_id].to_s
      return render json: { error: "Non hai accesso a questa conversazione" }, status: :forbidden
    end

    render json: conversation_payload(conversation), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Conversazione non trovata" }, status: :not_found
  end

  # GET /conversazioni/ricerca?q=term&company_id=:id
  # Restituisce gli id (e pochi metadati) delle conversazioni che contengono il testo
  def search
    term = params[:q].presence || params[:query].presence
    return render json: { error: "Parametro di ricerca mancante" }, status: :bad_request if term.blank?

    conversations = Conversation.left_outer_joins(:messages)
    conversations = conversations.where(company_id: params[:company_id]) if params[:company_id].present?

    like = "%#{term}%"
    conversations = conversations.where(
      "conversations.title ILIKE :term OR conversations.summary ILIKE :term OR messages.content ILIKE :term",
      term: like
    ).distinct.order(updated_at: :desc).limit(50)

    render json: {
      total: conversations.size,
      conversations: conversations.map do |c|
        {
          id: c.id,
          title: c.title,
          summary: c.summary,
          updated_at: c.updated_at.iso8601
        }
      end
    }, status: :ok
  end

  private

  def conversation_payload(conversation)
    {
      id: conversation.id,
      company_id: conversation.company_id,
      title: conversation.title,
      summary: conversation.summary,
      created_at: conversation.created_at.iso8601,
      updated_at: conversation.updated_at.iso8601,
      messages: conversation.messages.order(:created_at).map do |msg|
        {
          id: msg.id,
          role: msg.role,
          content: msg.content,
          created_at: msg.created_at.iso8601
        }
      end
    }
  end
end