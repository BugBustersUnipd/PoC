import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { DocumentsService } from '../../services/document.service';
import { HttpErrorResponse } from '@angular/common/http';

@Component({
  selector: 'app-ai-copilot',
  imports : [],
  templateUrl: './ai-copilot.html',
  styleUrl : './ai-copilot.css'
})
export class AiCopilot {
  private router = inject(Router);
  private documentsService = inject(DocumentsService);

  selectedFile?: File;
  companyId = 1; // TODO: dinamico

  onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files?.length) {
      this.selectedFile = input.files[0];
    }
  }

  upload() {
    if (!this.selectedFile){ 
      alert("Nessun file selezionato.")
      return;
    }
    this.documentsService.uploadDocument(this.selectedFile, this.companyId)
    .subscribe({
      next: (doc) => {
        // Upload riuscito, naviga alla pagina di anteprima
        this.router.navigate(['/aicopilotanteprima', doc.id]);
      },
      error: (err: any) => {
        // Se l'API restituisce un array di errori, mostra tutti
        if (err.error?.errors?.length) {
          alert(err.error.errors.join('\n'));
        } else {
          // Altrimenti messaggio generico
          console.error(err);
          alert("Si è verificato un errore durante l'upload");
        }
      }
    });
  }
}
