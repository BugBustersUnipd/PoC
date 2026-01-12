# DocumentsController - Gestisce upload e analisi documenti con OCR/AI
#
# I documenti vengono caricati, salvati con ActiveStorage, e analizzati in background 
# dove viene estratto testo (OCR) e analizzati metadati via Amazon Bedrock.
#
# Endpoints:
# - GET /documents?company_id=:id → lista documenti azienda
# - POST /documents → upload nuovo documento (trigger analisi async)
# - GET /documents/:id → dettaglio documento con risultati analisi
#
# Questo controller:
# - Gestisce upload file tramite ActiveStorage
# - Triggera job di analisi in background
# - Serve risultati analisi completata
class DocumentsController < ApplicationController
  # Per API-only: non serve CSRF token (usiamo JWT/API key in produzione)
  # In dev, le richieste vengono comunque validate se arrivano da browser

  # GET /documents?company_id=:id
  # Lista tutti i documenti caricati da un'azienda (più recenti prima)
  def index
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    # @company è variabile d'istanza: visibile in tutta l'azione e nelle view (non usate in API)
    # Convenzione Rails: @ per variabili condivise, niente @ per variabili locali
    @company = Company.find_by(id: company_id)
    return render json: { error: "Azienda non trovata" }, status: :not_found unless @company

    # order(created_at: :desc) → SQL: ORDER BY created_at DESC
    # :desc è simbolo Ruby (immutabile, efficiente come chiave)
    @documents = @company.documents.order(created_at: :desc)
    render json: DocumentSerializer.serialize_collection(@documents), status: :ok
  end

  # POST /documents
  # Carica un nuovo documento e avvia analisi AI in background
  #
  # Flow:
  # 1. Valida company_id
  # 2. Crea record Document con file allegato (ActiveStorage)
  # 3. Lancia job async per OCR + analisi Bedrock
  # 4. Ritorna subito con status "pending" (analisi completerà dopo)
  def create
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    company = Company.find_by(id: company_id)
    return render json: { error: "Azienda non trovata" }, status: :not_found unless company

    # build crea record in memoria (non salvato ancora nel DB)
    # Associa automaticamente company_id
    @document = company.documents.build(document_params)

    # save ritorna true/false (validation + insert DB)
    if @document.save
      # Lo stato di default del documento è "pending"
      # Il job aggiornerà status → "processed" quando completo
      AnalyzeDocumentJob.perform_later(@document.id)

      # status: :created → HTTP 201 (risorsa creata con successo)
      render json: DocumentSerializer.serialize(@document), status: :created
    else
      # full_messages converte errori ActiveRecord in array di stringhe leggibili
      # Es: ["Original file can't be blank", "Original file must be PDF or image"]
      render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /documents/:id
  # Recupera dettagli documento inclusi risultati analisi (se completata)
  def show
    @document = Document.find(params[:id])

    # Controllo autorizzazione base: verifica company_id
    # to_s converte Integer in String per confronto sicuro
    company_id = params[:company_id]
    if company_id.present? && @document.company_id.to_s != company_id.to_s
      return render json: { error: "Non hai accesso a questo documento" }, status: :forbidden
    end

    render json: DocumentSerializer.serialize(@document), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Documento non trovato" }, status: :not_found
  end

  private

  # Strong Parameters: whitelist parametri accettati per sicurezza
  # require(:document) verifica presenza chiave "document" nel JSON
  # permit(:original_file) permette solo campo original_file
  # Previene mass-assignment attacks (utente non può settare campi arbitrari)
  def document_params
    params.require(:document).permit(:original_file)
  end
end
