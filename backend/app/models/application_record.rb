# ApplicationRecord: classe base per TUTTI i model (Company, Document, User, ecc.)
#
# COSA SONO I MODEL in Rails (ActiveRecord ORM):
#   - Rappresentano le tabelle del database (es: "companies" table → Company model)
#   - Forniscono metodi per SELECT/INSERT/UPDATE/DELETE senza scrivere SQL
#   - Company.find(1) = SELECT * FROM companies WHERE id=1
#   - Company.create(name: "X") = INSERT INTO companies (name) VALUES ('X')
#   - Validazioni, relazioni, callback (prima/dopo evento)
#
# primary_abstract_class:
#   - "primary" = questo è il base model del progetto
#   - "abstract" = non è legato a una tabella specifica (inheritance per altri model)
#   - Necessario in Rails 6+ (dove ci possono essere più inheritance chain)
#
# Tutti i model ereditano da qui, quindi metodi custom in questa classe
# sono disponibili a TUTTI i model (Company, Document, Tone, ecc.)
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
