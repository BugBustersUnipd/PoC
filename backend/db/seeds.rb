# Pulisce i dati esistenti (prima messaggi e conversazioni, poi toni e aziende)
Message.delete_all
Conversation.delete_all
Tone.delete_all
Company.delete_all

# Crea l’azienda principale
company = Company.create!(
  id: 1,
  name: "Acme",
  description: "Suite B2B"
)

# Crea alcuni toni per l’azienda
[
  [ "Simpatico",     "Tono amichevole e leggero" ],
  [ "Formale",       "Tono professionale e conciso" ],
  [ "Istituzionale", "Tono autorevole e preciso" ]
].each do |name, instructions|
  Tone.create!(
    name: name,
    instructions: instructions,
    company: company
  )
end

conversation = company.conversations.create!(title: "Esempio")
conversation.messages.create!(role: "user", content: "Scrivi un breve post di prova.")
conversation.messages.create!(role: "assistant", content: "Ecco un breve post di prova per la suite B2B di Acme.")

puts "Seed completato: Company #{company.id} (#{company.name}) con #{company.tones.count} toni e conversazione #{conversation.id}."
