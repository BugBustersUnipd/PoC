# Architettura Backend Nexum POC - Guida ai Principi SOLID

Questa guida descrive l'architettura attuale del backend Nexum, evidenziando come ogni componente aderisce ai principi SOLID.

---

## Panoramica Architettura

```
┌─────────────────────────────────────────────────────────────────┐
│                        CONTROLLERS                              │
│  (ImageGenerationController, TextGenerationController, ...)    │
│         ↓ usano Params per validazione                         │
│         ↓ usano Serializers per output                         │
│         ↓ delegano a Services via ApplicationController        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DiContainer                                │
│  (Dependency Injection Container - costruisce il grafo)        │
│  Provider sostituibili per test e configurazione               │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────────┐   ┌─────────────────────────────┐
│         AiService           │   │        ImageService         │
│      (orchestratore)        │   │       (orchestratore)       │
│                             │   │                             │
│ Dipendenze iniettate:       │   │ Dipendenze iniettate:       │
│ • text_generator            │   │ • image_validator           │
│ • conversation_manager      │   │ • image_generator           │
│ • prompt_builder            │   │ • image_storage             │
└─────────────────────────────┘   └─────────────────────────────┘
              │                               │
              ▼                               ▼
┌─────────────────────────────┐   ┌─────────────────────────────┐
│  AiTextGenerator            │   │  ImageValidator             │
│  ConversationManager        │   │  ImageGenerator             │
│  PromptBuilder              │   │  ImageStorage               │
└─────────────────────────────┘   └─────────────────────────────┘
```

---

## 1. Single Responsibility Principle (SRP)
> Ogni classe ha una sola responsabilità e un solo motivo per cambiare.

### Componenti e responsabilità:

| Classe | Responsabilità unica |
|--------|---------------------|
| `ImageGenerationParams` | Validare e normalizzare parametri input per immagini |
| `TextGenerationParams` | Validare e normalizzare parametri input per testo |
| `ImageValidator` | Verificare dimensioni supportate |
| `ImageGenerator` | Chiamare API Bedrock Nova Canvas |
| `ImageStorage` | Salvare immagini nel DB + ActiveStorage |
| `AiTextGenerator` | Chiamare API Bedrock Converse |
| `ConversationManager` | CRUD conversazioni e messaggi |
| `PromptBuilder` | Costruire system prompt e normalizzare messaggi |
| `ConversationSearchService` | Ricerche testuali nelle conversazioni |
| `GeneratedImageSerializer` | Formattare JSON per immagini |
| `TextGenerationSerializer` | Formattare JSON per testo generato |
| `ConversationSerializer` | Formattare JSON per conversazioni |
| `DocumentSerializer` | Formattare JSON per documenti |
| `ToneSerializer` | Formattare JSON per toni |

### Controller snelli

I controller fanno solo orchestrazione:

```ruby
# TextGenerationController
def create
  request_params = TextGenerationParams.new(...)   # 1. Valida input
  return render_error unless request_params.valid?
  
  result = ai_service.genera(...)                   # 2. Delega al service
  
  render json: TextGenerationSerializer.serialize(...)  # 3. Serializza output
end
```

---

## 2. Open/Closed Principle (OCP)
> Le classi sono aperte all'estensione ma chiuse alla modifica.

### Estensioni senza modifiche al core:

**Nuovo formato output:**
- Crei `GeneratedImageXmlSerializer`
- Non modifichi `ImageService` né controller

**Nuove dimensioni immagine:**
- Modifichi solo `ImageValidator.VALID_SIZES`
- Il resto del flusso rimane invariato

**Nuovo provider AI:**
- Crei `OpenAiTextGenerator` con stesso metodo `generate_text`
- Configuri DiContainer:
```ruby
DiContainer.ai_text_generator_provider = -> { OpenAiTextGenerator.new }
```
- `AiService` non cambia

---

## 3. Liskov Substitution Principle (LSP)
> Le implementazioni devono essere sostituibili senza alterare il comportamento.

### Contratti rispettati:

| Componente | Metodo | Comportamento atteso |
|------------|--------|---------------------|
| Text Generator | `generate_text(messages, system_prompt)` | Ritorna stringa |
| Image Generator | `generate(prompt, width, height, seed)` | Ritorna base64 |
| Image Validator | `validate_size!(width, height)` | Solleva `ArgumentError` se invalido |
| Image Storage | `save(company, prompt, ...)` | Ritorna `GeneratedImage` |
| Conversation Manager | `fetch_or_create_conversation(company, id)` | Ritorna `Conversation` |

Qualsiasi implementazione che rispetti questi contratti può essere sostituita.

---

## 4. Interface Segregation Principle (ISP)
> I client non dipendono da interfacce che non usano.

### Interfacce piccole e focalizzate:

- `ImageValidator` → solo `validate_size!`
- `PromptBuilder` → solo `build_system_prompt`, `normalize_messages`
- `ConversationManager` → solo gestione conversazioni
- `ImageGenerator` → solo generazione, non validazione né storage

### Controller con accesso limitato:

```ruby
class ApplicationController < ActionController::API
  private
  def ai_service      # Solo per generazione testo
  def image_service   # Solo per generazione immagini
end
```

`TonesController` e `ConversationsController` non accedono a `image_service`.

---

## 5. Dependency Inversion Principle (DIP)
> I moduli di alto livello dipendono da astrazioni, non da implementazioni concrete.

### Dependency Injection nei Service:

```ruby
class AiService
  def initialize(text_generator:, conversation_manager:, prompt_builder:)
    @text_generator = text_generator         # Iniettato
    @conversation_manager = conversation_manager
    @prompt_builder = prompt_builder
  end
end

class ImageService
  def initialize(image_validator:, image_generator:, image_storage:)
    @image_validator = image_validator
    @image_generator = image_generator
    @image_storage = image_storage
  end
end
```

### DiContainer con Provider sostituibili:

```ruby
class DiContainer
  class << self
    attr_writer :ai_text_generator_provider, :image_generator_provider, ...
  end

  def self.ai_text_generator
    @ai_text_generator ||= (@ai_text_generator_provider&.call || AiTextGenerator.new)
  end
end
```

### Client esterni iniettabili:

```ruby
class AiTextGenerator
  def initialize(client: nil, region: ...)
    @client = client || Aws::BedrockRuntime::Client.new(...)
  end
end
```

Nei test si passa un mock client senza toccare il codice di produzione.

---

## Struttura Directory

```
app/
├── controllers/
│   ├── application_controller.rb      # Helper centralizzati
│   ├── companies_controller.rb
│   ├── conversations_controller.rb
│   ├── documents_controller.rb
│   ├── image_generation_controller.rb
│   ├── text_generation_controller.rb
│   └── tones_controller.rb
│
├── serializers/
│   ├── conversation_serializer.rb
│   ├── document_serializer.rb
│   ├── generated_image_serializer.rb
│   ├── text_generation_serializer.rb
│   └── tone_serializer.rb
│
├── services/
│   ├── di_container.rb                # Dependency Injection
│   ├── ai_service.rb                  # Orchestratore testo
│   ├── ai_text_generator.rb           # Bedrock Converse API
│   ├── conversation_manager.rb        # CRUD conversazioni
│   ├── prompt_builder.rb              # Costruzione prompt
│   ├── image_service.rb               # Orchestratore immagini
│   ├── image_generator.rb             # Bedrock Nova Canvas
│   ├── image_validator.rb             # Validazione dimensioni
│   ├── image_storage.rb               # Persistenza immagini
│   ├── image_generation_params.rb     # Request object immagini
│   ├── text_generation_params.rb      # Request object testo
│   ├── conversation_search_service.rb # Ricerca conversazioni
│   └── document_analysis_service.rb   # Analisi documenti
│
└── models/
    ├── company.rb
    ├── conversation.rb
    ├── document.rb
    ├── generated_image.rb
    ├── message.rb
    └── tone.rb
```

---

## Vantaggi

| Aspetto | Beneficio |
|---------|-----------|
| **Testabilità** | Ogni componente testabile in isolamento con mock |
| **Manutenibilità** | Modifiche localizzate, basso rischio regressioni |
| **Estendibilità** | Nuovi provider/formati senza toccare il core |
| **Leggibilità** | Controller snelli, responsabilità chiare |
| **Flessibilità** | Provider sostituibili via DiContainer |

---

## Deviazioni Pragmatiche dai Principi SOLID

Non tutto il codice segue SOLID alla lettera. Alcune scelte sono compromessi consapevoli per evitare over-engineering.

### 1. Value Objects istanziati direttamente (Params, Serializers)

**Cosa succede:**
```ruby
# Nel controller
request_params = ImageGenerationParams.new(...)  # Istanziazione diretta
render json: GeneratedImageSerializer.serialize(...)  # Idem
```

**Perché non è un problema:**

| Caratteristica | Service (iniettare ✅) | Value Object (ok diretto) |
|----------------|----------------------|---------------------------|
| Side effects | Sì (API, DB, file) | No |
| Dipendenze esterne | Sì | No |
| Stato mutabile | Possibile | Immutabile |
| Difficile da testare | Sì senza mock | No, testabile direttamente |

I Params e Serializers sono **value object puri**: nessun I/O, nessun side effect. Iniettarli aggiungerebbe complessità senza benefici reali.

**Trade-off accettato:** Semplicità > purezza teorica per classi senza side effects.

---

### 2. Models ActiveRecord acceduti direttamente nei Service

**Cosa succede:**
```ruby
# In AiService
company = Company.find(company_id)
tono_db = company.tones.find_by(name: nome_tono)
```

**Perché lo facciamo:**

ActiveRecord è già un'astrazione del database. Wrapparlo ulteriormente in un Repository creerebbe:
- Codice boilerplate senza valore aggiunto
- Doppia indirezione per operazioni semplici
- Overhead cognitivo per chi legge il codice

**Quando useremmo un Repository:**
- Query complesse riutilizzate in più punti
- Logica di business nel recupero dati
- Necessità di cachare o aggregare dati

**Trade-off accettato:** Per un PoC con query semplici, ActiveRecord diretto è sufficiente. Un progetto enterprise potrebbe introdurre Repository.

---

### 3. Configurazione globale (costanti BEDROCK_CONFIG_*)

**Cosa succede:**
```ruby
# In AiTextGenerator
model_id = ::BEDROCK_CONFIG_GENERATION["model_id"]
```

**Perché non è iniettata:**

La configurazione è:
- Caricata una volta all'avvio da file YAML
- Immutabile durante il runtime
- Uguale per tutte le istanze

Iniettarla nei costruttori complicherebbe le signature senza benefici:
```ruby
# Over-engineering
def initialize(client: nil, region: nil, model_id: nil, max_tokens: nil, ...)
```

**Alternativa futura:** Se servissero configurazioni diverse per ambiente/tenant, si potrebbe iniettare un oggetto `Config` dedicato.

**Trade-off accettato:** Costanti globali per configurazione statica, injection per dipendenze con comportamento.

---

### 4. Service Locator pattern nel DiContainer

**Cosa succede:**
```ruby
# In ApplicationController
def ai_service
  @ai_service ||= DiContainer.ai_service
end
```

**Perché non è pura Dependency Injection:**

In Ruby/Rails non c'è un framework DI nativo come Spring (Java). Le alternative sono:
1. **Constructor injection nei controller** → Rails non lo supporta nativamente
2. **Service Locator (attuale)** → Funziona, testabile, pragmatico
3. **Gem come dry-container** → Dipendenza aggiuntiva per un PoC

**Mitigazioni applicate:**
- I service ricevono dipendenze via constructor (vera DI)
- DiContainer supporta provider sostituibili per test
- I controller accedono solo ai service di cui hanno bisogno

**Trade-off accettato:** Service Locator a livello controller, vera DI a livello service.

---

### 5. Nessuna interfaccia esplicita (Duck Typing)

**Cosa succede:**

Ruby non ha `interface` come Java. I contratti sono impliciti:
```ruby
# Contratto implicito: deve rispondere a generate_text(messages, system_prompt)
@text_generator.generate_text(messages, system_prompt)
```

**Perché va bene in Ruby:**

- Duck typing è idiomatico in Ruby
- I test verificano i contratti
- Documentazione nei commenti esplicita le aspettative

**Alternativa (non necessaria per PoC):**
```ruby
# Con Sorbet o dry-types per type checking statico
sig { params(messages: T::Array[Hash], system_prompt: String).returns(String) }
def generate_text(messages, system_prompt); end
```

**Trade-off accettato:** Duck typing documentato > interfacce esplicite per un PoC Ruby.

---

### 6. Error handling nei controller invece di middleware

**Cosa succede:**
```ruby
rescue ArgumentError => e
  render json: { error: e.message }, status: :unprocessable_entity
rescue ActiveRecord::RecordNotFound
  render json: { error: "Azienda non trovata" }, status: :not_found
rescue => e
  render json: { error: "Errore interno: #{e.message}" }, status: :internal_server_error
```

**Perché non un middleware globale:**

- Ogni controller gestisce errori specifici al suo dominio
- I messaggi di errore sono contestualizzati
- Facile capire cosa succede leggendo il controller

**Quando centralizzare:**
- Errori comuni a tutti gli endpoint (autenticazione, rate limiting)
- Logging strutturato uniforme
- Molti controller con logica identica

**Trade-off accettato:** Error handling locale per chiarezza, centralizzabile se cresce la duplicazione.

---

### Riepilogo Trade-off

| Deviazione | Giustificazione | Quando riconsiderare |
|------------|-----------------|---------------------|
| Params/Serializers diretti | Nessun side effect | Mai, sono value objects |
| ActiveRecord diretto | Query semplici | Query complesse riutilizzate |
| Config globale | Immutabile, unica | Multi-tenant, config dinamica |
| Service Locator | Rails non ha DI nativo | Mai se funziona |
| Duck typing | Idiomatico Ruby | Type safety critica (Sorbet) |
| Error handling locale | Errori specifici | Duplicazione eccessiva |

---

## Esempio: Aggiungere provider OpenAI

```ruby
# 1. Crea il nuovo generator (stesso contratto)
class OpenAiTextGenerator
  def generate_text(messages, system_prompt)
    # Implementazione OpenAI
  end
end

# 2. Configura DiContainer
DiContainer.ai_text_generator_provider = -> { OpenAiTextGenerator.new }
DiContainer.reset!

# 3. Fatto! AiService usa automaticamente OpenAI
```

---

## Esempio: Test con Mock

```ruby
class AiServiceTest < ActiveSupport::TestCase
  test "genera chiama il text_generator" do
    mock_generator = Minitest::Mock.new
    mock_generator.expect(:generate_text, "Risposta", [Array, String])

    service = AiService.new(
      text_generator: mock_generator,
      conversation_manager: ConversationManager.new,
      prompt_builder: PromptBuilder.new
    )

    result = service.genera("Ciao", company.id, "formale")
    assert_equal "Risposta", result[:text]
    mock_generator.verify
  end
end
```
