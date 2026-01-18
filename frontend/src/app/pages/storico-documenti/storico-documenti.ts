import { Component, inject, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { Router } from '@angular/router';
import { DocumentsService } from '../../services/document.service';
import { CommonModule } from '@angular/common';
import { interval, Subscription, switchMap } from 'rxjs';

@Component({
  selector: 'app-storico-documenti',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './storico-documenti.html',
  styleUrl: './storico-documenti.css',
})
export class StoricoDocumenti implements OnInit, OnDestroy {
  private router = inject(Router);
  private documentsService = inject(DocumentsService);
  private cdr = inject(ChangeDetectorRef);
  private pollingSub?: Subscription;
  documents: any[] = [];
  companyId = 1; // TODO: dinamico
  isLoading = true;
  error = '';

  ngOnInit() {
    this.loadDocuments();
  }

  ngOnDestroy() {
    this.pollingSub?.unsubscribe();
  }

  loadDocuments() {
    this.isLoading = true;
    this.documentsService.getDocuments(this.companyId).subscribe({
      next: (docs) => {
        this.documents = docs;
        this.isLoading = false;
        this.cdr.detectChanges();
        
        // Avvia polling se ci sono documenti in elaborazione
        this.checkAndStartPolling();
      },
      error: (err) => {
        console.error('Errore caricamento documenti:', err);
        this.error = 'Errore nel caricamento dei documenti';
        this.isLoading = false;
      }
    });
  }

  private checkAndStartPolling() {
    // Verifica se ci sono documenti in elaborazione
    const hasProcessingDocs = this.documents.some(
      doc => doc.status === 'processing' || doc.status === 'pending'
    );

    if (hasProcessingDocs) {
      this.startPolling();
    } else {
      // Se non ci sono più documenti in elaborazione, ferma il polling
      this.pollingSub?.unsubscribe();
    }
  }

  private startPolling() {
    // Evita polling multipli
    if (this.pollingSub && !this.pollingSub.closed) {
      return;
    }

    this.pollingSub = interval(2000)
      .pipe(
        switchMap(() => this.documentsService.getDocuments(this.companyId))
      )
      .subscribe({
        next: (docs) => {
          this.documents = docs;
          this.cdr.detectChanges();
          
          // Controlla se deve continuare il polling
          this.checkAndStartPolling();
        },
        error: (err) => {
          console.error('Errore polling documenti:', err);
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