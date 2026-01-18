import { Component, inject, OnInit, ChangeDetectorRef } from '@angular/core';
import { Router } from '@angular/router';
import { DocumentsService } from '../../services/document.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-storico-documenti',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './storico-documenti.html',
  styleUrl: './storico-documenti.css',
})
export class StoricoDocumenti implements OnInit {
  private router = inject(Router);
  private documentsService = inject(DocumentsService);
  private cdr = inject(ChangeDetectorRef);

  documents: any[] = [];
  companyId = 1; // TODO: dinamico
  isLoading = true;
  error = '';

  ngOnInit() {
    this.loadDocuments();
  }

  loadDocuments() {
    this.isLoading = true;
    this.documentsService.getDocuments(this.companyId).subscribe({
      next: (docs) => {
        this.documents = docs;
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Errore caricamento documenti:', err);
        this.error = 'Errore nel caricamento dei documenti';
        this.isLoading = false;
      }
    });
  }

  viewDocument(docId: number) {
    this.router.navigate(['/aicopilotanteprima', docId]);
  }

  navigateToUpload() {
    this.router.navigate(['/ai-copilot']);
  }

  getStatusLabel(status: string): string {
    const labels: { [key: string]: string } = {
      'processing': 'In elaborazione',
      'pending': 'In elaborazione',
      'completed': 'Completato',
      'failed': 'Errore'
    };
    return labels[status] || status;
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('it-IT', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }
}