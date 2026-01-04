import { ChangeDetectorRef, Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient  } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

interface Tone {
  id: number;
  name: string;
  instructions: string;
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
  tones: Tone[] = [];
  selectedTone = '';

  companyId = 1; // TODO: dinamico

  ngOnInit() {
    this.loadTones();
  }

  loadTones() {
  console.log('Inizio caricamento toni...');
  
  this.http
    .get<any>('http://localhost:3000/toni', {
      params: { company_id: this.companyId.toString() }
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
      company_id: this.companyId,
      conversation_id: null
    };

    this.http.post('http://localhost:3000/genera', payload)
      .subscribe({
        next: (response) => {
          this.router.navigate(['/risultato-generazione'], {
            state: { result: response }
          });
        },
        error: () => {
          alert('Errore nella generazione');
        }
      });
  }

  navigateToStoricoPrompt() {
    this.router.navigate(['/storico-prompt']);
  }
}
