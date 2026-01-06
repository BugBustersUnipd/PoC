class CompaniesController < ActionController::API
  # GET /companies
  def index
    companies = Company.order(:id).select(:id, :name, :description)
    render json: companies, status: :ok
  end
end
