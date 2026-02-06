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
    const input = event.target;
    if (input && input instanceof HTMLInputElement && input.files?.length) { //Bisogna sincerarsi che l'input sia di tipo HTMLInputElement poichè HTMLInputElement è l'interfaccia che serve per manipolare gli elementi di input nel DOM e fornisce l'accesso alla proprietà files.
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
      error: (err: HttpErrorResponse) => {
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
    NavigateToStoricoDocumenti() {
  this.router.navigate(['/storico-documenti']);
}
}

