import { Routes } from '@angular/router';
import { Analytics } from './pages/analytics/analytics';
import { AiAssistant } from './pages/ai-assistant/ai-assistant';
import { AiCopilot } from './pages/ai-copilot/ai-copilot';
import { StoricoPrompt } from './pages/storico-prompt/storico-prompt';
import { RisultatoGenerazione } from './pages/risultato-generazione/risultato-generazione';
import { ModificaGenerazione } from './pages/modifica-generazione/modifica-generazione';
import { Aicopilotconfidenza } from './pages/aicopilotconfidenza/aicopilotconfidenza';
import { Aicopilotanteprimadocumento } from './pages/aicopilotanteprimadocumento/aicopilotanteprimadocumento';

export const routes: Routes = [
  { path: 'analytics', component: Analytics },
  { path: 'ai-assistant', component: AiAssistant },
  { path: 'ai-copilot', component: AiCopilot },
  { path: 'storico-prompt', component: StoricoPrompt },
  { path: 'risultato-generazione', component: RisultatoGenerazione },
  { path: 'modifica-generazione', component: ModificaGenerazione },
  { path: 'aicopilotconfidenza', component: Aicopilotconfidenza },
  { path: 'aicopilotanteprimadocumento', component: Aicopilotanteprimadocumento },
  { path: 'aicopilotanteprima/:id', component: Aicopilotanteprimadocumento },
];