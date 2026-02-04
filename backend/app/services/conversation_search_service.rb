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
  #
  # Query SQL generata (semplificata):
  #   SELECT DISTINCT conversations.*
  #   FROM conversations
  #   LEFT OUTER JOIN messages ON messages.conversation_id = conversations.id
  #   WHERE conversations.company_id = ?
  #     AND messages.content ILIKE '%term%'
  #   ORDER BY conversations.updated_at DESC
  #   LIMIT 50
  #
  # @param company_id [Integer, nil] filtra per azienda (nil = tutte)
  # @param term [String, nil] termine ricerca (nil = tutte conversazioni)
  #
  # @return [ActiveRecord::Relation<Conversation>] query lazy (eseguita al .to_a / .each)
  #
  # Esempio:
  #   # Cerca "email" per company 1
  #   results = service.search(company_id: 1, term: "email")
  #   # => [<Conversation title: "Email marketing">, <Conversation summary: "Campagna email...">]
  #
  #   # Tutte conversazioni azienda
  #   all = service.search(company_id: 1, term: nil)
  def search(company_id:, term:)
    # Costruisce query incrementalmente (ActiveRecord::Relation è lazy)
    # left_outer_joins(:messages) = LEFT OUTER JOIN con tabella messages
    # Perché LEFT OUTER JOIN?
    # - Vogliamo trovare conversazioni anche se non hanno messaggi ancora
    # - Ricerca su title/summary funziona anche per conv vuote
    conversations = Conversation.left_outer_joins(:messages)

    # Filtra per company_id se presente
    # .present? = true se valore non è nil/empty/blank
    # Modifier if = condizionale su singola linea (Ruby idiomatico)
    # Equivalente: if company_id.present? then conversations = conversations.where(...) end
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
      # :term = placeholder SQL (bind parameter per sicurezza SQL injection)
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

    # .distinct = rimuove duplicati (conversazione può matchare su più messaggi)
    # Senza distinct: conversazione con 3 messaggi matching appare 3 volte
    # Con distinct: appare 1 volta sola
    #
    # .order(updated_at: :desc) = ordina per updated_at decrescente (più recente prima)
    # :desc = Symbol per "descending" (alternativa: order("updated_at DESC")
    #
    # .limit(50) = massimo 50 risultati (performance + UX)
    # 50 conversazioni è compromesso ragionevole tra completezza e velocità
    conversations.distinct.order(updated_at: :desc).limit(50)
  end
end
