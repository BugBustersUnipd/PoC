import { ChangeDetectorRef,Component, inject, OnInit, OnDestroy } from '@angular/core';
import { Router,ActivatedRoute } from '@angular/router';
import { DocumentsService } from '../../services/document.service';
import { interval, Subscription, switchMap } from 'rxjs';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-aicopilotanteprimadocumento',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './aicopilotanteprimadocumento.html',
  styleUrl:'./aicopilotanteprimadocumento.css'
})
export class Aicopilotanteprimadocumento implements OnInit, OnDestroy {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private documentsService = inject(DocumentsService);
  private cdr = inject(ChangeDetectorRef);

  document: any;
  companyId = 1;

  private pollingSub?: Subscription;
  
formatLabel(key: string | number | symbol): string {
  return String(key)
    .replace(/_/g, ' ')
    .replace(/\b\w/g, char => char.toUpperCase());
}

ngOnInit() {
  const id = Number(this.route.snapshot.paramMap.get('id'));
 // Prima volta carico immediatamente
 this.documentsService.getDocument(id, this.companyId).subscribe(doc => {
    this.document = doc;
    console.log("caricato direttamente senza polling")
    this.cdr.detectChanges();  
    if(doc.status === 'processing' || doc.status === 'pending'){
      this.startPolling(id);
    }
  });
}
  private startPolling(id: number){
  this.pollingSub = interval(2000)
    .pipe(
      switchMap(() =>
        this.documentsService.getDocument(id, this.companyId)
      )
    )
    .subscribe(doc => {
      this.document = doc;
      if (doc.status === 'completed' || doc.status === 'failed') {
        this.pollingSub?.unsubscribe();
      this.cdr.detectChanges();  
      }
    });
}

navigateToAiCoPilot() {
    this.router.navigate(['/ai-copilot']);
}

ngOnDestroy() {
  this.pollingSub?.unsubscribe();
    
  }
}
