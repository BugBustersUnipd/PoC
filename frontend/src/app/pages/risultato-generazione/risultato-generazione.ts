import { Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-risultato-generazione',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './risultato-generazione.html',
  styleUrl: './risultato-generazione.css',
})
export class RisultatoGenerazione implements OnInit {
  private router = inject(Router);
  
  result: any = null;
  generatedText: string = '';
  conversationId: number | null = null;

  ngOnInit() {
    // Recupera i dati passati dalla navigazione
    const state = history.state;
    
    if (state && state['result']) {
      this.result = state['result'];
      console.log(' Risultato ricevuto:', this.result);
      
      // Estrai il testo generato (adatta in base alla struttura della response del tuo backend)
      this.generatedText = this.result.text || this.result.content || this.result.generated_text || '';
      this.conversationId = this.result.conversation_id || null;
    } else {
      console.warn(' Nessun risultato trovato, reindirizzo...');
      // Se non ci sono dati, torna alla home
      this.router.navigate(['/']);
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
}