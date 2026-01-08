class TextGenerationController < ActionController::API
  def initialize
    @ai_service = DIContainer.ai_service
  end

  # POST /genera
  def create
    prompt     = params[:prompt]
    tone_name  = params[:tone]
    company_id = params[:company_id]
    conversation_id = params[:conversation_id]

    if prompt.blank? || tone_name.blank? || company_id.blank?
      return render json: { error: "prompt, tone e company_id sono obbligatori" }, status: :unprocessable_entity
    end

    result = @ai_service.genera(prompt, company_id, tone_name, conversation_id: conversation_id)
    render json: result, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Record non trovato: #{e.message}"
    render json: { error: "Azienda, tono o conversazione non trovati" }, status: :not_found
  rescue => e
    Rails.logger.error "Errore interno: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Errore interno: #{e.message}" }, status: :internal_server_error
  end
end