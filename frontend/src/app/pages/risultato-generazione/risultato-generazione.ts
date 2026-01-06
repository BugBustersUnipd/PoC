import { Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient  } from '@angular/common/http';

interface Conversation{
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
  private router = inject(Router);
  private http = inject(HttpClient);
  

  showConversations: boolean = false;
  conversations: Conversation[] = [];

  result: any = null;
  generatedText: string = '';
  conversationId: number | null = null;
  companyId: number | null = null;
  tone: string | null = null;
  newMessage: string = '';
  ngOnInit() {
    // Recupera i dati passati dalla navigazione
    const state = history.state;
    
    if (state && state['result']) {
      this.result = state['result'];
      this.companyId = state['company_id'] || null;
      this.tone = state['tone'] || null;
      console.log(' Risultato ricevuto:', this.result);
      
      // Estrai il testo generato (adatta in base alla struttura della response del tuo backend)
      this.generatedText = this.result.text || this.result.content || this.result.generated_text || '';
      this.conversationId = this.result.conversation_id || null;
    } else {
      console.warn(' Nessun risultato trovato, reindirizzo...');
      // Se non ci sono dati, torna alla home
      this.router.navigate(['/']);
    }
    this.loadConversation();
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

  salvaPost() {
    // TODO: implementa il salvataggio
    console.log('Salva il post');
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
      alert('Nessuna conversazione selezionata');
      return;
    }

    console.log('Apro la conversazione con id:', this.conversationId);
    console.log('Azienda id:', this.companyId);

    this.http
      .get<any>(`http://localhost:3000/conversazioni/${this.conversationId}`, {
        params: { company_id: this.companyId?.toString() || '' }
      })
      .subscribe({
        next: (res) => {
          // res include la conversazione e i messaggi
          this.conversations = res.messages || [];
          console.log('Messaggi caricati:', this.conversations);
        },
        error: (err) => {
          console.error('Errore caricamento conversazione:', err);
          alert('Errore nel caricamento della conversazione');
        }
      });
  }

  toggleConversations() {
    this.showConversations = !this.showConversations;
    console.log('Mostra conversazioni:', this.showConversations);
  }


  // Aggiunge un messaggio alla conversazione

  addConversation() {
    const testo = this.newMessage.trim();
    if (!testo) return;

    // POST su /genera con conversation_id
    this.http.post<any>('http://localhost:3000/genera', {
      prompt: testo,
      tone: this.tone,                // puoi usare un tono generico
      company_id: this.companyId,
      conversation_id: this.conversationId
    }).subscribe({
      next: (res) => {
        // Aggiunge in locale il messaggio dell'utente

        console.log(res['text']);
        console.log(res['conversation_id']);

        console.log('Messaggi aggiornati:', this.conversations);
        this.loadConversation();
        // resetta input
        this.newMessage = '';

      },
      error: (err) => {
        console.error('Errore aggiunta messaggio:', err);
        alert('Errore nell\'aggiunta del messaggio');
      }
    });
  }

  onAiMessageClick(message: any) {
    console.log('Messaggio AI cliccato:', message);
  }

  get hiddenClass(){
    if(this.showConversations){
      return {};
    }else{
      return {'hidden' : true};
    }
  }
}