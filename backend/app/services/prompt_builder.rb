# PromptBuilder - Costruttore di prompt per Amazon Bedrock Converse API
#
# Questo servizio prepara i messaggi nel formato specifico richiesto da Bedrock:
# - System prompt (ruolo, contesto, regole)
# - Messages array con formato [{role: "user", content: [{text: "..."}]}, ...]
#
# Bedrock Converse API ha requisiti precisi:
# 1. Messages deve iniziare con "user" (mai "assistant")
# 2. Non ci possono essere due messaggi consecutivi dello stesso ruolo
# 3. Content deve essere array di Hash con chiave :text
#
# Responsabilità: normalizzazione formato, non business logic
class PromptBuilder
  # Costruisce il system prompt con ruolo azienda, contesto, tono comunicativo
  #
  # System prompt = istruzioni permanenti per l'IA che definiscono:
  # - Identità: "Sei l'IA ufficiale di [azienda]"
  # - Contesto: descrizione azienda/prodotto
  # - Tono: formale, amichevole, tecnico, etc.
  # - Regole: no placeholder, no prefissi "Assistant:", testo pronto per invio
  #
  # Sintassi Ruby utilizzata:
  #   <<~PROMPT...PROMPT = heredoc con indentation stripping
  #   - <<~ rimuove automaticamente indentazione comune (whitespace leading)
  #   - .strip rimuove spazi/newline all'inizio e fine stringa
  #   - #{variable} = string interpolation (inserisce valore variabile)
  #
  # @param company_name [String] nome azienda (es. "Acme Corp")
  # @param description [String] descrizione/contesto azienda
  # @param tone_instructions [String] istruzioni tono (es. "Professionale e cordiale")
  #
  # @return [String] system prompt formattato pronto per Bedrock
  #
  # Esempio:
  #   builder.build_system_prompt(
  #     "TechStartup",
  #     "Vendiamo software CRM",
  #     "Tono tecnico ma accessibile"
  #   )
  #   # => "RUOLO: Sei l'IA ufficiale di TechStartup.\nCONTESTO: Vendiamo..."
  def build_system_prompt(company_name, description, tone_instructions)
    # <<~PROMPT è heredoc delimiter: tutto fino a PROMPT diventa stringa
    # ~ dopo << significa "rimuovi indentazione comune" (unindent)
    # .strip finale rimuove spazi/newline extra all'inizio e fine
    <<~PROMPT.strip
      RUOLO: Sei l'IA ufficiale di "#{company_name}".
      CONTESTO: #{description}
      TONO (enfatizzalo): #{tone_instructions}

      REGOLE:
      - Se la domanda non riguarda "#{company_name}" o viene chiesto qualcosa che non riguarda in generale un'azienda, rispondi cortesemente che non puoi aiutare.
      - Genera solo il testo richiesto, pronto per l'invio, senza aggiungere frasi prima o dopo, ad esempio: "Certamente!" oppure "se hai bisogno di altro, fammi sapere.".
      - Non usare prefissi come "Assistant:" o simili.
      - Non usare MAI placeholder tra parentesi quadre, il messaggio deve essere pronto per l'invio senza modifiche aggiuntive.
      - Parla come mittente del messaggio senza presentazioni.
    PROMPT
  end

  # Normalizza messaggi storico + testo corrente nel formato Bedrock Converse API
  #
  # Trasforma messaggi DB (Message ActiveRecord) nel formato richiesto:
  # [
  #   {role: "user", content: [{text: "Ciao"}]},
  #   {role: "assistant", content: [{text: "Salve"}]}
  # ]
  #
  # Gestisce edge cases:
  # - Messaggi consecutivi stesso ruolo: combina content con \n\n
  # - Storia inizia con "assistant": rimuove messaggi assistant iniziali
  # - Storia vuota: crea array con solo messaggio corrente
  #
  # @param context_messages [Array<Message>] messaggi storico dalla conversazione (max 10)
  # @param current_user_text [String] nuovo testo utente da aggiungere
  #
  # @return [Array<Hash>] messages array pronto per invoke_model Bedrock
  #
  # Esempio:
  #   # Storico: [{role: "user", content: "Ciao"}, {role: "assistant", content: "Salve"}]
  #   # Nuovo: "Come stai?"
  #   builder.normalize_messages(storico, "Come stai?")
  #   # => [
  #   #   {role: "user", content: [{text: "Ciao"}]},
  #   #   {role: "assistant", content: [{text: "Salve"}]},
  #   #   {role: "user", content: [{text: "Come stai?"}]}
  #   # ]
  def normalize_messages(context_messages, current_user_text)
    # Array vuoto, lo popoleremo con messaggi formattati
    messages = []

    # Processa ogni messaggio dello storico conversazione
    context_messages.each do |msg|
      # downcase converte in minuscolo ("User" => "user")
      # msg.role può essere nil, || "" fornisce default stringa vuota
      role = (msg.role || "").downcase
      
      # .presence ritorna nil se stringa è vuota/blank, altrimenti ritorna la stringa
      # Se content vuoto, usa "." come fallback (evita content vuoto che Bedrock rifiuta)
      content = msg.content.presence || "."

      # Combina messaggi consecutivi stesso ruolo (Bedrock non li accetta)
      # .any? verifica se array ha almeno un elemento
      # messages.last accede all'ultimo elemento array (nil se vuoto)
      # Se ultimo messaggio ha stesso role, appendi content con doppio newline
      if messages.any? && messages.last[:role] == role
        # [:content][0][:text] accede a Hash nested: messages.last = {content: [{text: "..."}]}
        # += concatena stringa, \n\n = doppio a capo per separare visivamente
        messages.last[:content][0][:text] += "\n\n#{content}"
      else
        # Aggiungi nuovo messaggio con formato Bedrock: content DEVE essere array di Hash
        # {text: content} è Hash, [{}] lo wrappa in array
        messages << { role: role, content: [{ text: content }] }
      end
    end

    # Aggiungi testo corrente utente
    # Se ultimo messaggio è già "user", appendi al content esistente
    if messages.any? && messages.last[:role] == "user"
      messages.last[:content][0][:text] += "\n\n#{current_user_text}"
    else
      # Altrimenti crea nuovo messaggio user
      messages << { role: "user", content: [{ text: current_user_text }] }
    end

    # Bedrock richiede che messages inizi con "user", MAI con "assistant"
    # .shift rimuove e ritorna primo elemento array (muta array originale)
    # while loop continua finché primo messaggio è "assistant"
    # messages.first ritorna primo elemento (nil se array vuoto)
    # && = operatore AND logico, verifica entrambe condizioni
    messages.shift while messages.first && messages.first[:role] == "assistant"

    # Se dopo pulizia array è vuoto (storico era solo assistant), crea messaggio corrente
    # .empty? ritorna true se array non ha elementi
    messages = [{ role: "user", content: [{ text: current_user_text }] }] if messages.empty?

    # Ritorna array normalizzato
    messages
  end
end