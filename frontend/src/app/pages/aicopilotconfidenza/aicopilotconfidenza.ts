import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-aicopilotconfidenza',
  imports: [],
  templateUrl: './aicopilotconfidenza.html',
  styleUrl: './aicopilotconfidenza.css',
})
export class Aicopilotconfidenza {
private router = inject(Router);

navigateToAiCopilotAnteprimaDocumento() {
    this.router.navigate(['/aicopilotanteprimadocumento']);
  }
}
