# Riepilogo Commenti Codice Backend
Questo documento riepiloga tutti i commenti aggiunti al codice backend per renderlo comprensibile anche a sviluppatori non familiari con Ruby/Rails.

### Controllers (7 file)
- ✅ `application_controller.rb` - Base controller con service helpers e memoization
- ✅ `text_generation_controller.rb` - Endpoint generazione testo con validazione
- ✅ `image_generation_controller.rb` - Endpoint generazione immagini con splat operator
- ✅ `tones_controller.rb` - CRUD toni con query optimization (includes)
- ✅ `conversations_controller.rb` - CRUD conversazioni con serializer
- ✅ `documents_controller.rb` - Upload documenti con background job
- ✅ `companies_controller.rb` - CRUD aziende base

### Services (15 file)

#### Core Orchestrators
- ✅ `di_container.rb` - Dependency Injection Container con provider registration
- ✅ `ai_service.rb` - Orchestratore generazione testo (8 step flow)
- ✅ `image_service.rb` - Orchestratore generazione immagini

#### Support Services
- ✅ `prompt_builder.rb` - Costruzione prompt con heredoc e normalizzazione
- ✅ `conversation_manager.rb` - CRUD conversazioni con MAX_CONTEXT_MESSAGES
- ✅ `conversation_search_service.rb` - Ricerca full-text con ILIKE PostgreSQL

#### AWS Integration
- ✅ `ai_text_generator.rb` - Chiamate Bedrock Converse API con fallback
- ✅ `image_generator.rb` - Chiamate Nova Canvas con JSON building

#### Validation & Storage
- ✅ `image_validator.rb` - Validazione dimensioni con freeze e any?
- ✅ `image_storage.rb` - Persistenza ActiveStorage con Base64 decode

#### Request Objects
- ✅ `image_generation_params.rb` - Validazione input immagini con attr_reader
- ✅ `text_generation_params.rb` - Validazione input testo

### Serializers (5 file)
- ✅ `generated_image_serializer.rb` - JSON response immagini con iso8601
- ✅ `text_generation_serializer.rb` - JSON response testo minimale
- ✅ `conversation_serializer.rb` - 3 metodi (detail, list, search) con nested data
- ✅ `document_serializer.rb` - JSON documenti con conditional filename
- ✅ `tone_serializer.rb` - JSON toni con nested company

### Models (6 file)
- ✅ `company.rb` - Aggregate root con has_many e dependent: :destroy
- ✅ `conversation.rb` - Associazioni belongs_to/has_many
- ✅ `message.rb` - Validazioni con VALID_ROLES e inclusion
- ✅ `tone.rb` - belongs_to optional: true per toni globali
- ✅ `document.rb` - Callbacks, enum status, validazioni custom, SHA256 checksum
- ✅ `generated_image.rb` - ActiveStorage, numericality validations, note dimensioni

### Jobs (1 file)
- ✅ `analyze_document_job.rb` - Background job per analisi documenti con Amazon Bedrock

## 🎯 Pattern Ruby Spiegati

### Sintassi Core
- `||=` - Memoization (caching instance variable)
- `&.` - Safe navigation operator (evita nil errors)
- `.presence` - Ritorna nil se blank, altrimenti valore
- `**` - Splat operator per keyword arguments
- `<<~` - Heredoc con indentation stripping
- `%w[...]` - Array di stringhe literal

### ActiveRecord
- `belongs_to` / `has_many` - Associazioni con dependent options
- `enum :status` - Stati con metodi generati (pending?, processing!)
- `validates` - Validazioni con presence, inclusion, numericality
- `before_validation` - Callback lifecycle
- `.find` vs `.find_by` - Eccezione vs nil
- `.includes` - Eager loading per N+1 prevention
- `.where.not` - Query negativa

### ActiveStorage
- `has_one_attached` - File attachment
- `.attached?` - Check presenza file
- `.attach(io:, filename:, content_type:)` - Upload file

### Ruby Idioms
- `attr_reader` / `attr_writer` / `attr_accessor` - Getter/setter generation
- `class << self` - Class methods definition
- `freeze` - Immutabilità costanti
- `!` suffix - Bang methods (mutazione o eccezione)
- `?` suffix - Predicate methods (ritorna boolean)
- Modifier `if`/`unless` - Condizionali inline
- Guard clauses - Early return pattern
