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
  imports: [FormsModule,CommonModule],
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

    //chiamata per il get delle companies
    this.http
      .get<Company[]>('http://localhost:3000/companies')
      .subscribe({ //subscribe per gestire la risposta asincrona, quando arriva la risposta esegue next o error
        next: (res) => {
          this.companies = res; //inserisce il risultato nella variabile companies
          if (this.companies.length > 0) {
            this.filterCompany = this.companies[0].id; //se ci sono companies, seleziona la prima come default
            this.loadTones(); //per la company selezionata, carica i toni
          }
          this.cdr.detectChanges(); //forza il rilevamento dei cambiamenti per aggiornare la UI
          console.log('Aziende caricate:', this.companies); 
        },
        error: (err) => {
          console.error('Errore caricamento aziende:', err);
          alert('Errore nel caricamento delle aziende');
        }
      });
  }

  /* Carica i toni associati alla company selezionata */
  loadTones() {
    console.log('Inizio caricamento toni...');
    
  this.http
    .get<any>(`http://localhost:3000/toni?company_id=${this.filterCompany}`)
    .subscribe({
      next: (res) => {
        console.log('Response completa:', res); //ha id e nome azienda (sotto company) e toni (sotto tones)
        console.log('Toni array:', res.tones);
        console.log('Numero toni:', res.tones?.length);
        
        this.tones = res.tones || []; //assegna i toni ricevuti alla variabile tones, o un array vuoto se non ci sono toni
        if (this.tones.length > 0) {
          this.selectedTone = ""; //ad ogni cambiamento di company, resetta il tono selezionato mettendo il l'option "Seleziona tono"
        }
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
      company_id: this.filterCompany,
      conversation_id: null,
      prompt: this.prompt,
      tone: this.selectedTone
    };
    this.http.post<any>('http://localhost:3000/genera', payload)
      .subscribe({
        next: (response) => {
          console.log('Risposta completa dopo post genera text:', response); //ha text e conversation_id
          this.router.navigate(['/risultato-generazione'], {

            state: { conversation_id: response.conversation_id ,company_id: this.filterCompany}
          });
        },
        error: (err) => {
          const errorData = err.error;
          const errorCode = errorData?.code || "UNKNOWN_ERROR";
          
          // per debug
          // console.error(`[${errorCode}]`, errorData?.details || err.message);

          if (errorCode === "SECURITY_GUARDRAIL_VIOLATION") {
            const safetyMsg = errorData?.message || "La richiesta è stata bloccata dalle policy di sicurezza.";
            alert(safetyMsg);
          } else {
            alert("Si è verificato un problema tecnico. Riprova più tardi.");
          }
        }
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
  this.router.navigate(['/storico-prompt'], {
    state: {
      companyId: this.filterCompany
    }
  });
}


  updateCompany(value: any) {
    this.filterCompanyChange.emit(this.filterCompany);
    this.loadTones();
  }
}
