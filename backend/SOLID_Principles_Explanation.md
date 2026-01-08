# Architettura Backend Nexum POC - Guida ai Principi SOLID

Questa guida descrive l'architettura attuale del backend Nexum, evidenziando come ogni componente è progettato per aderire ai principi SOLID. L'obiettivo è avere un sistema manutenibile, testabile ed estendibile.

## Panoramica dell'Architettura
Il backend è strutturato seguendo il pattern "Service Object" con un Container di Dependency Injection (DI) leggero. Le responsabilità sono nettamente separate tra Controller (gestione HTTP), Service Orchestrator (logica di business di alto livello) e classi specializzate (logica di basso livello).

---

## 1. Single Responsibility Principle (SRP)
**"Ogni classe deve avere una sola ragione per cambiare."**

Nel nostro progetto, questo principio è applicato rigorosamente separando le responsabilità in classi piccole e focalizzate.

### Controller
I controller non contengono logica di business. Si occupano solo di ricevere la richiesta HTTP, invocare il servizio corretto e restituire la risposta JSON.
*   **`TextGenerationController`**: Gestisce esclusivamente le richieste di generazione testo.
*   **`ImageGenerationController`**: Gestisce esclusivamente le richieste di generazione immagini.
*   **`ConversationsController`**: Gestisce il recupero e il salvataggio delle conversazioni.

### Servizi e Componenti
Invece di avere servizi enormi ("God Objects"), abbiamo diviso la logica:
*   **`AiService`**: Funge solo da *orchestratore*. Non sa *come* costruire un prompt o chiamare l'API, sa solo *chi* chiamare (PromptBuilder, AiTextGenerator).
*   **`PromptBuilder`**: La sua unica responsabilità è formattare le stringhe di input per l'AI.
*   **`ConversationManager`**: Gestisce esclusivamente il recupero e l'aggiornamento della cronologia nel database.
*   **`AiTextGenerator`**: Si occupa solo della chiamata tecnica al client Bedrock per il testo.

**Vantaggio**: Se cambia il formato del prompt, modifichiamo solo `PromptBuilder` senza rischiare di rompere la logica di salvataggio nel DB.

---

## 2. Open/Closed Principle (OCP)
**"Le entità software devono essere aperte all'estensione, ma chiuse alla modifica."**

L'architettura attuale permette di aggiungere nuove funzionalità senza modificare il codice esistente che funziona.

### Esempio: `DIContainer`
Il container per la Dependency Injection ci permette di cambiare le implementazioni dei servizi senza toccare i controller.
Se domani vogliamo introdurre un `AdvancedAiService`, possiamo registrarlo nel `DIContainer` o passarlo specificamente dove serve, senza dover riscrivere i controller che lo utilizzano.

### Esempio: Orchestrators
Classi come `AiService` e `ImageService` dipendono da interfacce implicite dei loro collaboratori. Se vogliamo supportare un nuovo provider di immagini, possiamo creare una nuova classe (es. `DalleImageGenerator`) che rispetta i metodi pubblici attesi (`generate`) e iniettarla al posto di quella attuale, senza cambiare una riga di codice dentro `ImageService`.

---

## 3. Liskov Substitution Principle (LSP)
**"Le sottoclassi devono essere sostituibili alle loro classi base."**

Sebbene Ruby non usi interfacce esplicite come Java, rispettiamo questo principio attraverso il "Duck Typing" disciplinato.

*   I controller si aspettano che il servizio iniettato risponda al metodo `call` o `generate`. Qualsiasi oggetto passato al controller (che sia `AiService`, un mock per i test, o una nuova implementazione) rispetta questo contratto.
*   Questo garantisce che il sistema si comporti in modo corretto indipendentemente dall'implementazione specifica del servizio che sta utilizzando in quel momento.

---

## 4. Interface Segregation Principle (ISP)
**"Molte interfacce specifiche sono meglio di una singola interfaccia generica."**

Abbiamo evitato di creare un unico "Mega Service" che fa tutto. I client (i controller) dipendono solo dai metodi strettamente necessari.

*   Il `TextGenerationController` interagisce con un servizio che offre solo metodi per il testo. Non ha accesso (e non vede) metodi per generare immagini.
*   L'`ImageGenerationController` usa un servizio dedicato alle immagini.

Questo disaccoppiamento assicura che una modifica alla logica delle immagini non ricompili o impatti in alcun modo la gestione del testo.

---

## 5. Dependency Inversion Principle (DIP)
**"Dipendere dalle astrazioni, non dalle concrezioni."**

Questo è il cuore del refactoring che abbiamo effettuato.

### Prima (Violazione DIP)
I controller istanziavano direttamente le loro dipendenze:
```ruby
class GeneratorController
  def create
    service = AiService.new # DIPENDENZA DIRETTA (Hardcoded)
    service.generate(...)
  end
end
```
Il controller era "incollato" a quella specifica classe `AiService`.

### Adesso (Rispetto DIP)
I controller ricevono le dipendenze dall'esterno (via costruttore o via Container):
```ruby
class TextGenerationController
  def initialize
    # Il controller chiede un'astrazione ("il servizio di AI"), non crea l'oggetto.
    @ai_service = DIContainer.resolve(:ai_service)
  end
end
```
Il `TextGenerationController` non si preoccupa di come `AiService` viene creato o di quali dipendenze interne esso abbia (come `PromptBuilder` o `AiTextGenerator`). Dipende solo dall'astrazione del servizio.

---

## Riassunto dei Vantaggi Attuali

1.  **Testabilità**: Possiamo testare `PromptBuilder` isolatamente senza effettuare chiamate API reali. Possiamo testare i Controller con dei Mock dei servizi.
2.  **Manutenibilità**: Il codice è diviso in piccoli file logici. È facile trovare dove risiede un bug.
3.  **Scalabilità**: Aggiungere nuove feature (es. un nuovo tipo di generazione) è semplice e non rischia di rompere le feature esistenti.
