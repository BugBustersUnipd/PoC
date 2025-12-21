Rails.application.routes.draw do
  # Il router di Rails: qui dichiari le "regole" che dicono
  # quale controller/action deve gestire una certa richiesta HTTP.
  # Le regole sono lette dall’alto verso il basso: la prima che matcha viene usata.
  #
  # Dove nascono: le dichiari in config/routes.rb. Rails le carica quando avvii il server (in dev si ricaricano se il file cambia).
  # Cosa fanno: mappano Verbo HTTP + Path → Controller#Action.
  # Come si usano: facendo una richiesta HTTP a quell’URL (browser, curl, codice).

  # GET /up → controlla lo stato dell’app.
  # `as: :rails_health_check` crea l'helper `rails_health_check_path`
  # utile per link o test.
  get "up" => "rails/health#show", as: :rails_health_check

  # POST /genera → GeneratorController#create
  # Serve per generare il testo via AI.
  # Il body JSON del client (es. prompt, tone, company_id) sarà in `params`
  # e, se necessario, in `request.body.read`.
  post "genera", to: "generator#create"

  # GET /toni → GeneratorController#index
  # Restituisce la lista dei toni. Puoi passare query string
  # come `?company_id=1` e leggerla con `params[:company_id]` nel controller.
  get "toni", to: "generator#index"

  # GET /conversazioni → GeneratorController#conversations
  # Restituisce la lista delle conversazioni per una company
  get "conversazioni", to: "generator#conversations"

  # Esempio di root (pagina principale) — al momento non usata:
  # root "posts#index"
end
