# TonesController - Gestisce la lettura dei toni di comunicazione aziendali
#
# Endpoint: GET /toni?company_id=:id
# Output: { company: {...}, tones: [{id, name, instructions}, ...] }
#
# Questo controller:
# - Recupera i toni associati a un'azienda
# - Valida che company_id sia presente e valido
# - Serializza la risposta in formato consistente
class TonesController < ApplicationController
  # GET /toni?company_id=:id
  # Recupera tutti i toni di comunicazione configurati per un'azienda
  #
  # I toni definiscono come l'AI deve scrivere (formale, amichevole, tecnico, etc.)
  def index
    company_id = params[:company_id]
    return render json: { error: "company_id mancante" }, status: :bad_request if company_id.blank?

    # find_by restituisce nil se non trova (vs find che lancia eccezione)
    company = Company.find_by(id: company_id)
    return render json: { error: "Azienda non trovata" }, status: :not_found unless company

    # company.tones è associazione ActiveRecord (has_many)
    tones = company.tones
    
    # Serializer centralizza la formattazione JSON
    # Evita duplicazione: se cambia il formato, si modifica solo il serializer
    render json: ToneSerializer.serialize_collection(company, tones), status: :ok
  end
end