# ConversationsController - Gestisce le conversazioni tra utenti e AI
#
# Una conversazione mantiene lo storico dei messaggi (user/assistant) per contesto continuativo.
# Endpoints:
# - GET /conversazioni?company_id=:id → lista conversazioni
# - GET /conversazioni/:id → dettaglio conversazione con messaggi
# - GET /conversazioni/ricerca?q=term → ricerca full-text
#
# Questo controller:
# - Gestisce CRUD conversazioni
# - Implementa autorizzazione base (company_id matching)
# - Delega ricerca testuale a ConversationSearchService
class ConversationsController < ApplicationController
  # GET /conversazioni?company_id=:id
  # Lista le conversazioni recenti di un'azienda (max 50, ordinate per aggiornamento)
  def index
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    # where ritorna ActiveRecord::Relation (lazy query)
    # order/limit sono chainabili: query SQL eseguita solo al render
    # Pattern: Conversation.where(...).order(...).limit(...) → SELECT * FROM conversations WHERE ... ORDER BY ... LIMIT ...
    conversations = Conversation.where(company_id: company_id).order(updated_at: :desc).limit(50)
    
    # serialize_list formatta solo campi essenziali (senza messaggi completi)
    render json: ConversationSerializer.serialize_list(conversations), status: :ok
  end

  # GET /conversazioni/:id
  # Recupera una conversazione con tutti i suoi messaggi
  def show
    # includes(:messages) esegue eager loading (1 query invece di N+1)
    # Senza includes: 1 query per conversation + 1 query PER OGNI messaggio
    # Con includes: 1 query per conversation + 1 query per TUTTI i messaggi (JOIN o subquery)
    conversation = Conversation.includes(:messages).find(params[:id])

    # Controllo autorizzazione base: verifica che l'azienda richiesta coincida
    # .present? è opposto di .blank?: true se ha valore non-vuoto
    if params[:company_id].present? && conversation.company_id.to_s != params[:company_id].to_s
      return render json: { error: "Non hai accesso a questa conversazione" }, status: :forbidden
    end

    # serialize include tutti i messaggi annidati
    render json: ConversationSerializer.serialize(conversation), status: :ok
  rescue ActiveRecord::RecordNotFound
    # find lancia eccezione se ID non esiste (vs find_by che ritorna nil)
    render json: { error: "Conversazione non trovata" }, status: :not_found
  end

  # GET /conversazioni/ricerca?q=term&company_id=:id
  # Ricerca full-text in titolo, summary e contenuto messaggi
  def search
    # .presence ritorna valore se presente, altrimenti nil
    # Idiom Ruby: term = params[:q].presence || params[:query].presence
    # Permette alias q/query nello stesso endpoint
    term = params[:q].presence || params[:query].presence
    return render json: { error: "Parametro di ricerca mancante" }, status: :bad_request if term.blank?

    # Delega logica di ricerca a service dedicato (SRP)
    # Motivo: query complessa con JOIN, ILIKE, DISTINCT
    # Meglio separare dal controller per testabilità e riuso
    conversations = conversation_search_service.search(
      company_id: params[:company_id],
      term: term
    )

    render json: ConversationSerializer.serialize_search_results(conversations), status: :ok
  end

  private

  # Helper privato per accedere al service di ricerca
  # Memoization: istanza creata una volta per richiesta
  def conversation_search_service
    @conversation_search_service ||= ConversationSearchService.new
  end
end