Rails.application.routes.draw do
  # Il router di Rails: qui dichiari le "regole" che dicono
  # quale controller/action deve gestire una certa richiesta HTTP.
  # Le regole sono lette dall’alto verso il basso: la prima che matcha viene usata.
  #
  # Dove nascono: le dichiari in config/routes.rb. Rails le carica quando avvii il server (in dev si ricaricano se il file cambia).
  # Cosa fanno: mappano Verbo HTTP + Path → Controller#Action.
  # Come si usano: facendo una richiesta HTTP a quell’URL (browser, curl, codice).

  # GET /up → controlla lo stato dell’app.
  # Input: nessuno. Output: 200 OK con payload di health.
  # `as: :rails_health_check` crea l'helper `rails_health_check_path` utile per link o test.
  get "up" => "rails/health#show", as: :rails_health_check

  # POST /genera → GeneratorController#create
  # Input (body JSON): prompt (req), tone (req), company_id (req), conversation_id (opt).
  # Output: { text, conversation_id } oppure errore 4xx/5xx.
  post "genera", to: "generator#create"

  # GET /toni → GeneratorController#index
  # Input (query): company_id (req).
  # Output: { company: {id,name}, tones: [ {id,name,instructions} ] } o 404 se company mancante.
  get "toni", to: "generator#index"

  # GET /conversazioni → GeneratorController#conversations
  # Input (query): company_id (req).
  # Output: lista max 50 conversazioni della company [{id,title,created_at,updated_at,summary}].
  get "conversazioni", to: "generator#conversations"

  # GET /conversazioni/:id → GeneratorController#show_conversation
  # Input: :id (req path), company_id (opt query per verifica ownership).
  # Output: conversazione con metadati e messages ordinati [{id,role,content,created_at}].
  get "conversazioni/:id", to: "generator#show_conversation"

  # GET /conversazioni/ricerca → GeneratorController#search_conversations
  # Input (query): q o query (req), company_id (opt filtro).
  # Output: { total, conversations: [{id,title,summary,updated_at}] }.
  get "conversazioni/ricerca", to: "generator#search_conversations"

  # POST /genera-immagine → GeneratorController#create_image
  # Genera un'immagine che può essere associata a una conversazione testuale.
  # Input (body JSON): prompt (req), company_id (req), conversation_id (opt), width (opt), height (opt), seed (opt).
  # Output: { image_url, image_id, width, height, model_id, created_at }.
  post "genera-immagine", to: "generator#create_image"

  resources :documents, only: [ :index, :create, :show ]

  # Esempio di root (pagina principale) — al momento non usata:
  # root "posts#index"
end
