# ApplicationJob: classe base per tutti i background job (attività asincrone)
#
# COSA SONO I JOB (ActiveJob) in Rails:
#   - Attività che esegui IN BACKGROUND, non nella richiesta HTTP
#   - Es: analisi documenti, invio email, elaborazione immagini (richiedono tempo)
#   - Senza job: il browser attende fino a completamento → timeout/freeze UI
#   - Con job: richiesta HTTP ritorna subito (status 202), job gira su worker separato
#
# COME FUNZIONA:
#   - .perform_later(args) = schedula il job, ritorna subito, worker lo fa dopo
#   - Adapter: sidekiq (Redis), Delayed Job, pure ruby (dev), ecc.
#   - Retry automatico: se il job fallisce, riprovare N volte (es: Deadlock, network error)
#   - Discard: se fallimento permanente (es: record cancellato), scarta senza retry infinito
#
# retry_on e discard_on commentate: disabilitate, però disponibili se servono
class ApplicationJob < ActiveJob::Base
  # Uncomment per abilitare retry automatico su deadlock DB (concorrenza)
  # retry_on ActiveRecord::Deadlocked

  # Uncomment per ignorare errore se il record non esiste più al momento dell'esecuzione
  # discard_on ActiveJob::DeserializationError
end
