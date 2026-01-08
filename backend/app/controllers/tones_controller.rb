class TonesController < ActionController::API
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
end