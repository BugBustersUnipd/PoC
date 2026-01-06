import { ChangeDetectorRef, inject ,Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { forkJoin } from 'rxjs';
import { ConversationsService } from '../../services/conversation.service';

interface PromptRow {
  conversationId: number;
  prompt: string;
  risultato: string;
  timestamp: string;
}

@Component({
  selector: 'app-storico-prompt',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './storico-prompt.html',
  styleUrl: './storico-prompt.css',
})
export class StoricoPrompt implements OnInit {
  private cdr = inject(ChangeDetectorRef);
  rows: PromptRow[] = [];
  loading = true;

  companyId = 1; // TODO: dinamico

  constructor(private conversationsService: ConversationsService) {}

  ngOnInit() {
    this.loadStorico();
  }

  loadStorico() {
    this.loading = true;
    
    this.conversationsService.getConversations(this.companyId).subscribe({
      next: (conversations) => {

        const requests = conversations.map(c =>
          this.conversationsService.getConversationDetail(c.id, this.companyId)
        );

        forkJoin(requests).subscribe({
          next: (details) => {
            this.rows = [];
            
            details.forEach(conv => {
              const userMsg = conv.messages.find((m: any) => m.role === 'user');
              const aiMsg = conv.messages.find((m: any) => m.role === 'assistant');
              
              if (userMsg && aiMsg) {
                this.rows.push({
                  conversationId: conv.id,
                  prompt: userMsg.content,
                  risultato: aiMsg.content,
                  timestamp: aiMsg.created_at
                });
                
              }
            });
            this.loading = false;
            this.cdr.detectChanges();
          },
          error: () => this.loading = false
        });
      },
      error: () => this.loading = false
    });
  }
}
