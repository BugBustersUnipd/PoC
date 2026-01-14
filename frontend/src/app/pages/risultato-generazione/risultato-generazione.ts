import { Component, inject, OnInit, ChangeDetectorRef } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient  } from '@angular/common/http';
import { ActivatedRoute } from '@angular/router';
interface Message{
  id: number;
  role: string;
  content: string;
  created_at: string;
}

@Component({
  selector: 'app-risultato-generazione',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './risultato-generazione.html',
  styleUrl: './risultato-generazione.css',
})
export class RisultatoGenerazione implements OnInit {
  private route = inject(ActivatedRoute);
  private cdr = inject(ChangeDetectorRef);
  private router = inject(Router);
  private http = inject(HttpClient);

  // Variabili di stato interfaccia
  showConversations: boolean = false;
  showImageInput: boolean = false; // MOSTRA/NASCONDE IL BOX PER IL PROMPT IMMAGINE
  
  conversation: Message[] = [];
  result: any = null;
  
  // Dati generazione
  generatedText: string = '';
  generatedImage: string | null = null;
  conversationId: number | null = null;
  companyId: number | null = null;
  tone: string | null = null;
  newMessage: string = '';
  imagePrompt: string = ''; 


ngOnInit() {
  const state = history.state;

  // Sottoscriviamo ai parametri dell'URL
  this.route.queryParams.subscribe(params => {
    const id_param = state?.['conversation_id'] || null;
    if (id_param) {
      //se è stato generato un testo (pulsante Genera) allora carica la conversazione
      this.conversationId = +id_param;
      this.companyId = state?.['company_id']|| null;
      this.tone = state?.['tone'] || null;
      this.loadConversation();
    } //se è stata generata un'immagien (quindi non associata ad una conversazione) allora vengono passati i dati 
    else if (state && state.result) {
      this.result = state.result;
      
      if (state.result.image_url) {
        this.generatedImage = `http://localhost:3000${state.result.image_url}`;
        this.generatedText = '';
      } 

      this.cdr.detectChanges();
    }
    else {
      console.warn('Nessun dato disponibile');
    }
  });
}


  toggleImageInput() {
    this.showImageInput = !this.showImageInput;
    if (!this.imagePrompt) {
       this.imagePrompt = ''; 
    }
  }

  confermaGenerazioneImmagine() {
    if (!this.imagePrompt.trim()) {
      alert('Scrivi un prompt per l\'immagine.');
      return;
    }

    const payload: any = {
      prompt: this.imagePrompt,
      company_id: this.companyId
    };

    if (this.conversationId) {
      payload.conversation_id = this.conversationId;
    }

    console.log('Generazione Immagine con Prompt dedicato:', payload);

    this.http.post('http://localhost:3000/genera-immagine', payload)
      .subscribe({
        next: (response: any) => {
          console.log('Immagine generata:', response);

          if (response.image_url) {
            this.generatedImage = `http://localhost:3000${response.image_url}?t=${Date.now()}`;
          }

          this.showImageInput = false;
          this.loadConversation();
        },
        error: (err) => {
          console.error('Errore generazione immagine:', err);
          alert('Errore durante la generazione dell\'immagine.');
        }
      });
  }

  loadConversation() {
    if (!this.conversationId) return;

    this.http
      .get<any>(`http://localhost:3000/conversazioni/${this.conversationId}`, {
        params: { company_id: this.companyId?.toString() || '' }
      })
      .subscribe({
        next: (res) => {
          this.conversation = res.messages || [];
          
          // Se l'immagine è parte della conversazione o del risultato, gestiscila qui
          // if (res.image_url) {
          //   this.generatedImage = `http://localhost:3000${res.image_url}`;
          // }

          const assistantMessages = this.conversation.filter(m => m.role === 'assistant');
          if (assistantMessages.length > 0) {
             this.generatedText = assistantMessages[assistantMessages.length - 1].content;
             this.cdr.detectChanges();
          }
        },
        error: (err) => console.error('Errore caricamento:', err)
      });

    // Carica le immagini associate a questa conversazione
    this.http
      .get<any>('http://localhost:3000/immagini', {
        params: { 
          company_id: this.companyId?.toString() || '',
          conversation_id: this.conversationId.toString()
        }
      })
      .subscribe({
        next: (res) => {
          // La rotta restituisce { total, limit, offset, images: [...] }
          // Se ci sono immagini, prendiamo l'ultima generata (o la prima, dipende dall'ordine del DB)
          if (res.images && res.images.length > 0) {
            // Prendiamo l'ultima immagine dell'array (assumendo che siano in ordine cronologico o che ti interessi una sola)
            const lastImage = res.images[res.images.length - 1];
            
            // Costruiamo l'URL completo
            this.generatedImage = `http://localhost:3000${lastImage.image_url}`;
            
            // Se vuoi mostrare il prompt usato per l'immagine nel box di input (opzionale)
            if (lastImage.prompt) {
               this.imagePrompt = lastImage.prompt;
            }
          } else {
            // Nessuna immagine associata a questa conversazione
            this.generatedImage = null;
          }
          this.cdr.detectChanges();
        },
        error: (err) => {
          console.error('Errore caricamento immagini associate:', err);
        }
      });
  }
  



  addMessage() {
    const testo = this.newMessage.trim();
    if (!testo) return;

    this.http.post<any>('http://localhost:3000/genera', {
      company_id: this.companyId,
      conversation_id: this.conversationId,
      prompt: testo,
      tone: this.tone
    }).subscribe({
      next: (res) => {
        // console.log(res['text']);
        // console.log(res['conversation_id']);

        console.log('Messaggi aggiornati:', this.conversation);
        this.loadConversation();
        this.generatedText = res['text'] || '';

      },
      error: (err) => {
        console.log('conversation_id:', this.conversationId);
        console.log('company_id:', this.companyId);
        console.log('prompt:', testo);
        console.log('tone:', this.tone);
        console.error('Errore aggiunta messaggio:', err);
        alert('Errore nell\'aggiunta del messaggio');
      }
    });
  }

  
  toggleConversations() {
    this.showConversations = !this.showConversations;
  }

  onAiMessageClick(message: any) {
    const isImage = message.content.includes('/rails/') || message.content.includes('http');

    if (isImage) {
      // CASO IMMAGINE:
      // Se il messaggio storico è un'immagine, puliamo il testo e mostriamo l'immagine.
      this.generatedText = '';
      
      // Gestione URL: se manca il dominio (es. path relativo Rails), lo aggiungiamo
      if (message.content.startsWith('http')) {
         this.generatedImage = message.content;
      } else {
         this.generatedImage = `http://localhost:3000${message.content}`;
      }
      
    } else {
      // CASO TESTO:
      // Se il messaggio storico è testo, lo mostriamo e nascondiamo l'immagine.
      this.generatedText = message.content;
      this.generatedImage = null; 
    }

    this.cdr.detectChanges();
  }


  esci() { this.router.navigate(['/ai-assistant']); }
  
  get hiddenClass() { return this.showConversations ? {} : {'hidden' : true}; }
}
