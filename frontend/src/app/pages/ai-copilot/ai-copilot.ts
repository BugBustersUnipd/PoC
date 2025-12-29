import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';


@Component({
  selector: 'app-ai-copilot',
  imports: [],
  templateUrl: './ai-copilot.html',
  styleUrl: './ai-copilot.css',
})
export class AiCopilot {
private router = inject(Router);

navigateToConfidenza() {
     this.router.navigate(['/aicopilotconfidenza']);
  }
}
