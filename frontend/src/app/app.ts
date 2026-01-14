import { Component, signal } from '@angular/core';
import { RouterOutlet, RouterLink } from '@angular/router';
import { Analytics } from "./pages/analytics/analytics";
import { AiAssistant } from './pages/ai-assistant/ai-assistant';
import { AiCopilot} from './pages/ai-copilot/ai-copilot';
import { StoricoPrompt } from './pages/storico-prompt/storico-prompt';
import { RisultatoGenerazione } from './pages/risultato-generazione/risultato-generazione';
import { ModificaGenerazione } from './pages/modifica-generazione/modifica-generazione';
import { Aicopilotconfidenza } from './pages/aicopilotconfidenza/aicopilotconfidenza';
import { Aicopilotanteprimadocumento } from './pages/aicopilotanteprimadocumento/aicopilotanteprimadocumento';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('ProvaAngular');
}
