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

  # POST /genera → TextGenerationController#create
  # Input (body JSON): prompt (req), tone (req), company_id (req), conversation_id (opt).
  # Output: { text, conversation_id } oppure errore 4xx/5xx.
  post "genera", to: "text_generation#create"

  # GET /companies → CompaniesController#index
  # Output: elenco aziende [{id,name,description}]
  resources :companies, only: [ :index ]

  # GET /toni → TonesController#index
  # Input (query): company_id (req).
  # Output: { company: {id,name}, tones: [ {id,name,instructions} ] } o 404 se company mancante.
  get "toni", to: "tones#index"

  # GET /conversazioni → ConversationsController#index
  # Input (query): company_id (req).
  # Output: lista max 50 conversazioni della company [{id,title,created_at,updated_at,summary}].
  get "conversazioni", to: "conversations#index"

  # GET /conversazioni/:id → ConversationsController#show
  # Input: :id (req path), company_id (opt query per verifica ownership).
  # Output: conversazione con metadati e messages ordinati [{id,role,content,created_at}].
  get "conversazioni/:id", to: "conversations#show"

  # GET /conversazioni/ricerca → ConversationsController#search
  # Input (query): q o query (req), company_id (opt filtro).
  # Output: { total, conversations: [{id,title,summary,updated_at}] }.
  get "conversazioni/ricerca", to: "conversations#search"

  # POST /genera-immagine → ImageGenerationController#create
  # Genera un'immagine che può essere associata a una conversazione testuale.
  # Input (body JSON): prompt (req), company_id (req), conversation_id (opt), width (opt), height (opt), seed (opt).
  # Output: { image_url, image_id, width, height, model_id, created_at }.
  post "genera-immagine", to: "image_generation#create"

  # GET /immagini → ImagesController#index
  # Recupera tutte le immagini generate da una compagnia.
  # Input (query): company_id (req), limit (opt, default 50), offset (opt, default 0), conversation_id (opt).
  # Output: { total, limit, offset, images: [{id,prompt,width,height,model_id,image_url,conversation_id,created_at}] }.
  get "immagini", to: "images#index"

  # GET /immagini/:id → ImagesController#show
  # Recupera i dettagli di una singola immagine.
  # Input: id (path req), company_id (query opt per verifica ownership).
  # Output: { id, prompt, width, height, model_id, image_url, company_id, conversation_id, created_at }.
  get "immagini/:id", to: "images#show"

  # GET /documenti → DocumentsController#index
  # Recupera tutti i documenti caricati da una compagnia.
  # Input (query): company_id (req), limit (opt, default 50), offset (opt, default 0).
  # Output: { total, limit, offset, documents: [{id,title,content_type,file_url,created_at}] }.
  get "documenti", to: "documents#index"

  # GET /documenti/:id → DocumentsController#show
  # Recupera i dettagli di un singolo documento.
  # Input: :id (req path), company_id.
  # Output: { id, title, content_type, file_url, status, analysis_results, created_at }.
  get "documenti/:id", to: "documents#show"

  resources :documents, only: [ :index, :create, :show ]

  # Esempio di root (pagina principale) — al momento non usata:
  # root "posts#index"
end
