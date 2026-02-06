import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(), //serve a configurare l'ascolto di eventi errore, fa tutto angular sotto il cofano
    provideRouter(routes), //per il routing (app.routes.ts)
    provideHttpClient(withFetch()), //per le chiamate http
  ],
};
