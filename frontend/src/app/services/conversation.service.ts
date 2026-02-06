import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Conversation { //queste sono tipo le struct di c
  id: number;
  created_at: string;
  updated_at: string;
}

@Injectable({ providedIn: 'root' }) //fa DI in tutte le componenti, non serve aggiungerla nei providers di ogni componente
export class ConversationsService {

  private baseUrl = 'http://localhost:3000';

  constructor(private http: HttpClient) {}

  getConversations(companyId: number): Observable<Conversation[]> {
    return this.http.get<Conversation[]>(
      `${this.baseUrl}/conversazioni`,
      { params: { company_id: companyId } }
    );
  }

  getConversationDetail(id: number, companyId: number): Observable<any> {
    return this.http.get<any>(
      `${this.baseUrl}/conversazioni/${id}`,
      { params: { company_id: companyId } }
    );
  }
}
