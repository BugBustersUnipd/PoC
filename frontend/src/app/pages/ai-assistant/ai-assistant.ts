import { ChangeDetectorRef, Component, EventEmitter, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient  } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

interface Tone {
  id: number;
  name: string;
  instructions: string; //magari serve in futuro
}

interface Company{
  id: number;
  name: string;
  description: string; //magari serve in futuro
}

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

  companies: Company[] = [];
  tones: Tone[] = [];
  selectedTone = '';

  // qui è un buon pattern che siano @Input e @Output ma al momento per il poc non stiamo lavorando molto a moduli, una pagina è un solo ts
  filterCompany!: number;
  filterCompanyChange = new EventEmitter<number>();

  ngOnInit() {
    this.loadCompanies();
  }
  loadCompanies() {
    console.log('Inizio caricamento aziende...');
    this.http
      .get<Company[]>('http://localhost:3000/companies')
      .subscribe({
        next: (res) => {
          this.companies = res;
          if (this.companies.length > 0) {
            this.filterCompany = this.companies[0].id;
            this.loadTones();
          }
          this.cdr.detectChanges();
          console.log('Aziende caricate:', this.companies);
        },
        error: (err) => {
          console.error('Errore caricamento aziende:', err);
          alert('Errore nel caricamento delle aziende');
        }
      });
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
    this.http.post<any>('http://localhost:3000/genera', payload)
      .subscribe({
        next: (response) => {
          this.router.navigate(['/risultato-generazione'], {

            //passa come parametro conversation_id l'id della conversazione (aggiungo per permettere la visualizzazione della singola conversazione nello storico, con tutti i suoi dettagli)
            queryParams: { conversation_id: response.conversation_id },

            //i dati che ci servono per recuperare tono e la company (entrambe per permettere la modifica, perchè usano GET /genera)
            state: { company_id: this.filterCompany, tone: this.selectedTone }
          });
        },
        error: () => alert('Errore nella generazione')
      });
  }
  

  generaImmagine() {
    if (!this.prompt.trim()) {
      alert('Inserisci un prompt per generare l\'immagine');
      return;
    }

    const payload = {
      prompt: this.prompt,
      company_id: this.filterCompany,
      conversation_id: null 
    };

    this.http.post<any>('http://localhost:3000/genera-immagine', payload)
      .subscribe({
        next: (response) => {
          this.router.navigate(['/risultato-generazione'], {
            state: { 
              result: response, //ci serve per avere l'effetiva immagine
              isImage: true //permette di capoire che è un'immagine, altrimenti risultato-generazione non sa se usare renderizzare un testo o un'immagine
            }
          });
        },
        error: (err) => {
          console.error('Errore generazione immagine:', err);
          alert('Errore durante la generazione dell\'immagine');
        }
      });
  }

  
  navigateToStoricoPrompt() {
    this.router.navigate(['/storico-prompt']);
  }


  updateCompany(value: any) {
    this.filterCompanyChange.emit(this.filterCompany);
    this.loadTones();
  }
}
