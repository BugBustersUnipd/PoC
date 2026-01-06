import { ChangeDetectorRef, Component, EventEmitter, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient  } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

interface Tone {
  id: number;
  name: string;
  instructions: string;
}

// interface Company{

// }

@Component({
  selector: 'app-ai-assistant',
  standalone: true,
  imports: [FormsModule,CommonModule,],
  templateUrl: './ai-assistant.html',
  styleUrl: './ai-assistant.css',
})
export class AiAssistant implements OnInit {
  private router = inject(Router);
  private http = inject(HttpClient);
  private cdr = inject(ChangeDetectorRef);

  prompt = '';

  // Aggiunte aziende di prova
  companies = [
    { id: 1, name: 'Azienda Alpha' },
    { id: 2, name: 'Beta Corp' },
    { id: 3, name: 'Gamma LLC' }
  ];
  tones: Tone[] = [];
  selectedTone = '';

  // qui è un buon pattern che siano @Input e @Output ma al momento per il poc non stiamo lavorando molto a moduli, una pagina è un solo ts
  filterCompany!: number;
  filterCompanyChange = new EventEmitter<number>();

  ngOnInit() {
    this.filterCompany = this.companies[0].id;
    this.loadTones();
  }
  
  loadTones() {
    console.log('Inizio caricamento toni...');
    
  this.http
    .get<any>('http://localhost:3000/toni', {
      params: { company_id: this.filterCompany.toString() }
    })
    .subscribe({
      next: (res) => {
        console.log('Response completa:', res);
        console.log('Toni array:', res.tones);
        console.log('Numero toni:', res.tones?.length);
        
        this.tones = res.tones || [];
        this.cdr.detectChanges();
        
        console.log('this.tones dopo assegnazione:', this.tones);
      },
      error: (err) => {
        console.error('Errore caricamento toni:', err);
        alert('Errore nel caricamento dei toni');
      }
    });
  }
  
  genera() {
    if (!this.prompt.trim()) {
      alert('Inserisci un prompt');
      return;
    }
    
    if (!this.selectedTone) {
      alert('Seleziona un tono');
      return;
    }
    
    const payload = {
      prompt: this.prompt,
      tone: this.selectedTone,
      company_id: this.filterCompany,
      conversation_id: null
    };
    
    this.http.post('http://localhost:3000/genera', payload)
    .subscribe({
        next: (response) => {
          this.router.navigate(['/risultato-generazione'], {
            state: { 
              result: response,
              company_id: this.filterCompany,
              tone: this.selectedTone
            }
          });
        },
        error: () => {
          alert('Errore nella generazione');
        }
      });
  }
  

  generaImmagine() {
    // 1. Validazione: serve almeno il prompt
    if (!this.prompt.trim()) {
      alert('Inserisci un prompt per generare l\'immagine');
      return;
    }

    // 2. Prepara i dati (nota: company_id è obbligatorio)
    const payload = {
      prompt: this.prompt,
      company_id: this.filterCompany,
      conversation_id: null 
    };

    console.log('Invio richiesta immagine:', payload);

    // 3. Chiamata all'API /genera-immagine
    this.http.post('http://localhost:3000/genera-immagine', payload)
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

  
  navigateToStoricoPrompt() {
    this.router.navigate(['/storico-prompt']);
  }


  updateCompany(value: any) {
    this.filterCompanyChange.emit(this.filterCompany);
    // è sufficiente decommentare il codice appena aggiunte altre companies, load carica a seconda di filterCompany
    // this.loadTones();
    console.log('Qui devono essere riaggiornati i toni e messi quelli dell\'azienda ', this.filterCompany);
  }
}
