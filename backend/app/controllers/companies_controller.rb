# CompaniesController - Gestisce le aziende (tenant del sistema)
#
# Endpoint: GET /companies
# Output: [{ id, name, description }, ...]
#
# Questo controller:
# - Fornisce lista aziende disponibili nel sistema
# - Endpoint pubblico in PoC (autenticazione da aggiungere in produzione)
#
# Nota: In un sistema enterprise, questo endpoint sarebbe protetto e filtrato
# per mostrare solo aziende accessibili all'utente autenticato.
class CompaniesController < ApplicationController
  
  # GET /companies
  # Lista tutte le aziende configurate nel sistema
  def index
    # order(:id) garantisce ordinamento consistente (utile per pagination futura)
    companies = Company.order(:id).select(:id, :name, :description)
    render json: companies, status: :ok
  end
end
