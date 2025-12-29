class DocumentsController < ApplicationController
  # Per API-only: non serve CSRF token (usiamo JWT/API key in produzione)
  # In dev, le richieste vengono comunque validate se arrivano da browser

  # POST /documents
  def create
    @document = Document.new(document_params)

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
    render json: document_json(@document)
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
      status: document.status,
      doc_type: document.doc_type,
      ai_data: document.ai_data,
      created_at: document.created_at.iso8601,
      updated_at: document.updated_at.iso8601
    }
  end
end
