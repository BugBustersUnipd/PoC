# ApplicationController: classe base per tutti i controller API
# 
# Eredita da ActionController::API (non ::Base) perché:
#   - Questo è un API-only app (no HTML, no view rendering)
#   - Disabilita automaticamente middleware non necessari (session, CSRF token per GET, ecc.)
#   - Render json automatico se non specifichi render
#   - Integrazione websocket, session, flash disabilitate
#
# Tutti i controller ereditano da questa classe, quindi filtri/metodi qui
# si applicano globalmente a tutte le rotte
class ApplicationController < ActionController::API
end
