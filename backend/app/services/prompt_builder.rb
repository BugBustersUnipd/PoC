class PromptBuilder
  def build_system_prompt(company_name, description, tone_instructions)
    <<~PROMPT.strip
      RUOLO: Sei l'IA ufficiale di "#{company_name}".
      CONTESTO: #{description}
      TONO: #{tone_instructions}

      REGOLE:
      - Genera solo il testo richiesto, pronto per l'invio, senza aggiungere frasi prima o dopo, ad esempio: "Certamente!" oppure "se hai bisogno di altro, fammi sapere.".
      - Non usare prefissi come "Assistant:" o simili.
      - Parla come mittente del messaggio senza presentazioni.
      - Non usare MAI placeholder tra parentesi quadre, il messaggio deve essere pronto per l'invio senza modifiche aggiuntive.
    PROMPT
  end

  def normalize_messages(context_messages, current_user_text)
    messages = []

    # Processa messaggi dello storico
    context_messages.each do |msg|
      role = (msg.role || "").downcase
      content = msg.content.presence || "."

      if messages.any? && messages.last[:role] == role
        messages.last[:content][0][:text] += "\n\n#{content}"
      else
        messages << { role: role, content: [{ text: content }] }
      end
    end

    # Aggiungi testo attuale
    if messages.any? && messages.last[:role] == "user"
      messages.last[:content][0][:text] += "\n\n#{current_user_text}"
    else
      messages << { role: "user", content: [{ text: current_user_text }] }
    end

    # Assicurati che inizi con "user"
    messages.shift while messages.first && messages.first[:role] == "assistant"

    messages = [{ role: "user", content: [{ text: current_user_text }] }] if messages.empty?

    messages
  end
end