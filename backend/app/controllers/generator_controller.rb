class GeneratorController < ActionController::API
  # POST /genera
  def create
    prompt     = params[:prompt]
    tone_name  = params[:tone]
    company_id = params[:company_id]
    conversation_id = params[:conversation_id]

    if prompt.blank? || tone_name.blank? || company_id.blank?
      return render json: { error: "prompt, tone e company_id sono obbligatori" }, status: :unprocessable_entity
    end

    result = AiService.new.genera(prompt, company_id, tone_name, conversation_id: conversation_id)
    render json: result, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Record non trovato: #{e.message}"
    render json: { error: "Azienda, tono o conversazione non trovati" }, status: :not_found
  rescue => e
    Rails.logger.error "Errore interno: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Errore interno: #{e.message}" }, status: :internal_server_error
  end

  # GET /toni?company_id=:id
  def index
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    company = Company.find_by(id: company_id)
    return render json: { error: "Azienda non trovata" }, status: :not_found unless company

    tones = company.tones.select(:id, :name, :instructions)
    render json: {
      company: { id: company.id, name: company.name },
      tones: tones
    }, status: :ok
  end

  # GET /conversazioni?company_id=:id
  def conversations
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    conversations = Conversation.where(company_id: company_id).order(updated_at: :desc).limit(50)
    render json: conversations.as_json(only: [ :id, :title, :created_at, :updated_at, :summary ])
  end
end
