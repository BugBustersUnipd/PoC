import { Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient  } from '@angular/common/http';
import { ChangeDetectorRef } from '@angular/core';
interface Message{
  id: number;
  role: string;
  content: string;
  created_at: string; //sevoglio aggiungere la data
}
@Component({
  selector: 'app-risultato-generazione',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './risultato-generazione.html',
  styleUrl: './risultato-generazione.css',
})

export class RisultatoGenerazione implements OnInit {
  private cdr = inject(ChangeDetectorRef);
  private router = inject(Router);
  private http = inject(HttpClient);
  

  showConversations: boolean = false;
  conversation: Message[] = [];

  result: any = null;
  generatedText: string = '';
  generatedImage: string | null = null;
  conversationId: number | null = null;
  companyId: number | null = null;
  tone: string | null = null;
  newMessage: string = '';
  ngOnInit() {
    // Recupera i dati passati dalla navigazione
    const state = history.state;
    if (state && state['result']) {
      // questo per ora non serve ma lascio magari poi serve
      this.result = state['result']; 
      this.companyId = state['company_id'] || null;
      this.tone = state['tone'] || null;
      this.conversationId = state['result'].conversation_id || null;
      console.log(' Risultato ricevuto:', this.result);
      

      //commentato perche non serve più teoricamente
      // Estrai il testo generato (adatta in base alla struttura della response del tuo backend) 
      // this.generatedText = this.result.text || this.result.content || this.result.generated_text || '';
      // this.generatedImage = this.result.image_url || null;
      
      this.loadConversation();
      
      // Estrai il testo generato (adatta in base alla struttura della response del tuo backend)
      this.generatedText = this.result.text || this.result.content || this.result.generated_text || '';
      if (this.result.image_url) {
        this.generatedImage = `http://localhost:3000${this.result.image_url}`;
      } else {
        this.generatedImage = null;
      }      
    } else {
      console.warn(' Nessun risultato dalla navigazione, carico ultima conversazione...');
    }
  }

  navigateToModificaGenerazione() {
    this.router.navigate(['/modifica-generazione'], {
      state: { result: this.result }
    });
  }

  rigenera() {
    // TODO: implementa la rigenerazione
    console.log('Rigenera con lo stesso prompt');
  }
  scarta() {
    // Torna alla home
    this.router.navigate(['/']);
  }

  pubblica() {
    // TODO: implementa la pubblicazione
    console.log('Pubblica il contenuto');
  }

  loadConversation() {
    if (!this.conversationId) {
      return;
    }

  this.http
    .get<any>(`http://localhost:3000/conversazioni/${this.conversationId}`, {
      params: { company_id: this.companyId?.toString() || '' }
    })
    .subscribe({
      next: (res) => {
        this.conversation = res.messages || [];
        console.log('Conversazione caricata:', this.conversation);
        // Forza l'aggiornamento della variabile usata nel template
        // Usiamo la logica del getter ma la salviamo esplicitamente
        const assistantMessages = this.conversation.filter(m => m.role === 'assistant');
        if (assistantMessages.length > 0) {
           const lastContent = assistantMessages[assistantMessages.length - 1].content;
           this.generatedText = lastContent;
           this.cdr.detectChanges()
        }
      },
      error: (err) => {
        console.error('Errore:', err);
      }
    });
}

  toggleConversations() {
    this.showConversations = !this.showConversations;
    // console.log('Mostra conversazioni:', this.showConversations);
  }


  addMessage() {
    const testo = this.newMessage.trim();
    if (!testo) return;

    // 1. VERIFICA MODALITÀ: Se c'è un'immagine a video, siamo in modalità immagine
    const isImageMode = !!this.generatedImage;

    // 2. CONFIGURAZIONE CHIAMATA
    let url = '';
    let payload: any = {};

    if (isImageMode) {
      // --- MODALITÀ IMMAGINE ---
      url = 'http://localhost:3000/genera-immagine';
      payload = {
        prompt: testo,                  // La modifica richiesta dall'utente
        company_id: this.companyId,
        conversation_id: this.conversationId // Importante per mantenere il filo del discorso
      };
    } else {
      // --- MODALITÀ TESTO ---
      url = 'http://localhost:3000/genera';
      payload = {
        prompt: testo,
        tone: this.tone,
        company_id: this.companyId,
        conversation_id: this.conversationId
      };
    }

    // 3. ESECUZIONE DELLA CHIAMATA
    this.http.post<any>(url, payload).subscribe({
      next: (res) => {
        console.log('Risposta modifica:', res);

        // Se è la prima volta che parliamo, il backend ci darà un ID conversazione
        if (res.conversation_id) {
          this.conversationId = res.conversation_id;
        }

        // 4. AGGIORNAMENTO UI
        if (isImageMode) {
          // Se il backend ci restituisce una nuova immagine, aggiorniamo la view
          if (res.image_url) {
            this.generatedImage = `http://localhost:3000${res.image_url}`;
          }
        } else {
          // Se è testo, aggiorniamo il testo
          this.generatedText = res.text || '';
        }

        // Ricarichiamo la chat per vedere il messaggio appena scambiato
        this.loadConversation();
        
        // Puliamo l'input
        this.newMessage = '';
      },
      error: (err) => {
        console.error('Errore modifica:', err);
        alert('Errore durante la modifica.');
      }
    });
  }

  onAiMessageClick(message: any) {
    console.log('Messaggio AI cliccato:', message);
  }

  //per aggiungere la classe hidden (e toglierla) al click del mouse
  get hiddenClass(){
    if(this.showConversations){
      return {};
    }else{
      return {'hidden' : true};
    }
  }

  esci() {
    // Naviga verso la pagina dell'AI Assistant
    this.router.navigate(['/ai-assistant']);
  }
  
  generaImmagine() {
    // 1. Validazione: serve almeno il prompt
    if (!this.result.content.trim()) {
      alert('Inserisci un prompt per generare l\'immagine');
      return;
    }

    // 2. Prepara i dati (nota: company_id è obbligatorio)
    const payload = {
      prompt: this.result.content,
      company_id: this.companyId,
      conversation_id: null 
    };

    console.log('Invio richiesta immagine:', payload);

    // 3. Chiamata all'API /genera-immagine
    this.http.post(  `http://localhost:3000/genera-immagine/${this.conversationId}`, payload)
      .subscribe({
        next: (response) => {
          console.log('Immagine generata:', response);
          // 4. Vai alla pagina risultati passando la risposta
          this.router.navigate(['/risultato-generazione'], {
            state: { result: response }
          });
        },
        error: (err) => {
          console.error('Errore generazione immagine:', err);
          alert('Errore durante la generazione dell\'immagine. Controlla la console.');
        }
      });
  }

}
