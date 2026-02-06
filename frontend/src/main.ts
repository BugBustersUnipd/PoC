import { bootstrapApplication } from '@angular/platform-browser';
import { App } from './app/app';
import { appConfig } from './app/app.config';
/**chiama le configurazioni dell'applicazione, routing, http client etc e l'applicazione vera e propria App */
bootstrapApplication(App, appConfig) 
  .catch(err => console.error(err));
