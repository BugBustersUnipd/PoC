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
    const id_param = params['conversation_id'];

    if (id_param) {
      //se è stato generato un testo (pulsante Genera) allora carica la conversazione
      this.conversationId = +id_param;
      this.companyId = state?.['company_id'] || null;
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
  }



  addMessage() {
    const testo = this.newMessage.trim();
    if (!testo) return;

    this.http.post<any>('http://localhost:3000/genera', {
      prompt: testo,
      tone: this.tone,
      company_id: this.companyId,
      conversation_id: this.conversationId
    }).subscribe({
      next: (res) => {
        // console.log(res['text']);
        // console.log(res['conversation_id']);

        console.log('Messaggi aggiornati:', this.conversation);
        this.loadConversation();
        this.generatedText = res['text'] || '';

      },
      error: (err) => {
        console.error('Errore aggiunta messaggio:', err);
        alert('Errore nell\'aggiunta del messaggio');
      }
    });
  }

  
  toggleConversations() {
    this.showConversations = !this.showConversations;
  }

  onAiMessageClick(message: any) {
    console.log('Msg click:', message);
  }

  rigenera() { console.log('Todo rigenera'); }
  pubblica() { console.log('Todo pubblica'); }
  scarta() { this.router.navigate(['/']); }
  esci() { this.router.navigate(['/ai-assistant']); }
  
  get hiddenClass() { return this.showConversations ? {} : {'hidden' : true}; }
}
