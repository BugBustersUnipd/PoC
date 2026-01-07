import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { DocumentsService } from '../../services/document.service';

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
    if (!this.selectedFile) return;

    this.documentsService
      .uploadDocument(this.selectedFile, this.companyId)
      .subscribe(doc => {
        this.router.navigate(['/aicopilotanteprima', doc.id]);
      });
  }
}
