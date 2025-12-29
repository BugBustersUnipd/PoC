import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Conversation {
  id: number;
  title: string;
  summary: string;
  created_at: string;
  updated_at: string;
}

@Injectable({
  providedIn: 'root'
})
export class ConversationsService {

  private apiUrl = 'http://localhost:3000';

  constructor(private http: HttpClient) {}

  getConversations(companyId: number): Observable<Conversation[]> {
    const params = new HttpParams().set('company_id', companyId);
    return this.http.get<Conversation[]>(`${this.apiUrl}/conversazioni`, { params });
  }
}
