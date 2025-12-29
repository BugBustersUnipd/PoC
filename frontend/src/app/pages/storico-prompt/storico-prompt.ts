import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ConversationsService, Conversation } from '../../conversations';

@Component({
  selector: 'app-storico-prompt',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './storico-prompt.html',
  styleUrl: './storico-prompt.css',
})
export class StoricoPrompt implements OnInit {

  conversations: Conversation[] = [];
  filtered: Conversation[] = [];
  loading = false;

  companyId = 1; // recuperalo da auth o localStorage

  constructor(private conversationsService: ConversationsService) {}

  ngOnInit() {
    this.conversationsService.getConversations(this.companyId).subscribe({
      next: (data) => {
        this.conversations = data;
        this.filtered = data;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
      }
    });
  }

  search(term: string) {
    this.filtered = this.conversations.filter(c =>
      (c.title || '').toLowerCase().includes(term.toLowerCase()) ||
      (c.summary || '').toLowerCase().includes(term.toLowerCase())
    );
  }
}
