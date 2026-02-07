# ApplicationController - Controller base per l'API Rails
#
# Eredita da ActionController::API (versione leggera senza views/session per API-only)
# Tutti i controller applicativi ereditano da questa classe per condividere helper comuni.
#
# Fornisce:
# - Accesso centralizzato ai servizi tramite helper methods
# - Punto di estensione per funzionalità comuni (es. autenticazione, logging)
class ApplicationController < ActionController::API
	private

	# Helper per accedere al servizio di generazione testo AI
	#
	# Pattern Ruby:
	# - @ai_service è una variabile d'istanza (persiste per tutta la richiesta HTTP)
	# - ||= è "memoization": assegna solo se nil, evita chiamate multiple a DiContainer, fa lazy loading insomma
	# - DiContainer.ai_service restituisce un singleton configurato con tutte le dipendenze
	#
	# @return [AiService] istanza del servizio di generazione testo
	def ai_service
		@ai_service ||= DiContainer.ai_service
	end

	# Helper per accedere al servizio di generazione immagini
	#
	# Stesso pattern di ai_service ma per le immagini.
	# @return [ImageService] istanza del servizio di generazione immagini
	def image_service
		@image_service ||= DiContainer.image_service
	end
end
