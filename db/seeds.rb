# Pulisce i dati esistenti (prima i toni, poi le aziende)
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

puts "Seed completato: Company #{company.id} (#{company.name}) con #{company.tones.count} toni."
