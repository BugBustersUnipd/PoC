import { Routes } from '@angular/router';
import { AiAssistant } from './pages/ai-assistant/ai-assistant';
import { AiCopilot } from './pages/ai-copilot/ai-copilot';
import { StoricoPrompt } from './pages/storico-prompt/storico-prompt';
import { RisultatoGenerazione } from './pages/risultato-generazione/risultato-generazione';
import { Aicopilotanteprimadocumento } from './pages/aicopilotanteprimadocumento/aicopilotanteprimadocumento';

export const routes: Routes = [
  { path: 'ai-assistant', component: AiAssistant },
  { path: 'ai-copilot', component: AiCopilot },
  { path: 'storico-prompt', component: StoricoPrompt },
  { path: 'risultato-generazione', component: RisultatoGenerazione },
  { path: 'aicopilotanteprimadocumento', component: Aicopilotanteprimadocumento },
  { path: 'aicopilotanteprima/:id', component: Aicopilotanteprimadocumento },
];