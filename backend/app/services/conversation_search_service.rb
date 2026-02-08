# ConversationSearchService - Ricerca full-text su conversazioni e messaggi
#
# Permette ricerca su:
# - messages.content (testo messaggi user/assistant)
#
# Supporta:
# - Filtro per company_id (multi-tenancy)
# - Ricerca case-insensitive (ILIKE PostgreSQL)
# - Limit 50 risultati (performance)
# - Ordinamento per updated_at desc (più recenti prima)
#
# - Centralizza logica query complesse
# - Isola SQL da controller
# - Riusabile in API e background jobs
class ConversationSearchService
  # Cerca conversazioni per company e term di ricerca
  def search(company_id:, term:)
    # - Ricerca su title/summary funziona anche per conv vuote
    conversations = Conversation.left_outer_joins(:messages)

    # Filtra per company_id se presente
    conversations = conversations.where(company_id: company_id) if company_id.present?

    # Filtra per termine ricerca se presente
    if term.present?
      # Costruisce pattern LIKE con wildcard
      # "%#{term}%" = match parziale (es. term="email" trova "invia email", "email marketing")
      # % = wildcard SQL (0 o più caratteri)
      like = "%#{term}%"
      # .where con SQL raw per ILIKE (case-insensitive LIKE)
      # ILIKE = operatore PostgreSQL per case-insensitive matching
      #   "EMAIL" ILIKE "%email%" = true
      #   "EMAIL" LIKE "%email%" = false (case-sensitive)
      #
      # OR = qualsiasi condizione vera match (content)
      #
      # Sintassi Ruby:
      #   Multi-line string spezza query lunga per leggibilità
      #   term: like = named argument Hash {term: like}
      conversations = conversations.where(
        "messages.content ILIKE :term",
        term: like
      )
    end

    conversations.distinct.order(updated_at: :desc).limit(50) #limite risultati per performance
  end
end
