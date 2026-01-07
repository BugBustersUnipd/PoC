class DocumentsController < ApplicationController
  # Per API-only: non serve CSRF token (usiamo JWT/API key in produzione)
  # In dev, le richieste vengono comunque validate se arrivano da browser

  # GET /documents?company_id=:id
  def index
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    @company = Company.find_by(id: company_id)
    return render json: { error: "Azienda non trovata" }, status: :not_found unless @company

    @documents = @company.documents.order(created_at: :desc)
    render json: @documents.map { |doc| document_json(doc) }, status: :ok
  end

  # POST /documents
  def create
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    company = Company.find_by(id: company_id)
    return render json: { error: "Azienda non trovata" }, status: :not_found unless company

    @document = company.documents.build(document_params)

    if @document.save
      # Lanciamo il Job in background (lo stato di default è "pending")
      AnalyzeDocumentJob.perform_later(@document.id)

      render json: document_json(@document), status: :created
    else
      render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /documents/:id
  def show
    @document = Document.find(params[:id])

    # Verifica che la company_id nel header/params corrisponda
    company_id = params[:company_id]
    if company_id.present? && @document.company_id.to_s != company_id.to_s
      return render json: { error: "Non hai accesso a questo documento" }, status: :forbidden
    end

    render json: document_json(@document), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Documento non trovato" }, status: :not_found
  end

  private

  def document_params
    params.require(:document).permit(:original_file)
  end

  def document_json(document)
    {
      id: document.id,
      company_id: document.company_id,
      status: document.status,
      doc_type: document.doc_type,
      ai_data: document.ai_data,
      checksum: document.checksum,
      created_at: document.created_at.iso8601,
      updated_at: document.updated_at.iso8601,
      filename: document.original_file.attached? ? document.original_file.filename.to_s : nil
    }
  end
end
