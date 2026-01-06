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

      // this.result = state['result']; questo per ora non serve ma lascio magari poi serve
      this.companyId = state['company_id'] || null;
      this.tone = state['tone'] || null;
      this.conversationId = state['result'].conversation_id || null;
      console.log(' Risultato ricevuto:', this.result);
      

      //commentato perche non serve più teoricamente
      // Estrai il testo generato (adatta in base alla struttura della response del tuo backend) 
      // this.generatedText = this.result.text || this.result.content || this.result.generated_text || '';
      // this.generatedImage = this.result.image_url || null;
      
      this.loadConversation();
      
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
  if (!this.conversationId) return;

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
  
}