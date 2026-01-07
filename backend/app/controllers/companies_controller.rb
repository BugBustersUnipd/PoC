class CompaniesController < ActionController::API
  # GET /companies
  # Ritorna lista di tutte le aziende con campi basilari
  # 
  # Ottimizzazioni:
  #   - .order(:id) = garantisce risultato deterministico (non casuale)
  #   - .select(:id, :name, :description) = carica SOLO questi campi dal DB (riduce memoria e banda)
  #     Senza select, Rails carica TUTTI i campi della tabella companies
  #   - render json: converte automaticamente to_json (ActionController::API gestisce encoding)
  #   - status: :ok = HTTP 200 (non strettamente necessario, è il default, ma esplicito è meglio)
  #
  # Risposta:
  #   [{ "id": 1, "name": "Azienda A", "description": "..." }, ...]
  def index
    companies = Company.order(:id).select(:id, :name, :description)
    render json: companies, status: :ok
  end
end
