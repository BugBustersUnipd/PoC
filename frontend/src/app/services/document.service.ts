import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class DocumentsService {
  private baseUrl = 'http://localhost:3000';

  constructor(private http: HttpClient) {}

  uploadDocument(file: File, companyId: number): Observable<any> {
    const formData = new FormData();
    formData.append('document[original_file]', file);

    return this.http.post<any>(
      `${this.baseUrl}/documents?company_id=${companyId}`,
      formData
    );
  }

  getDocument(id: number, companyId: number): Observable<any> {
    return this.http.get<any>(
      `${this.baseUrl}/documents/${id}?company_id=${companyId}`
    );
  }

  getDocuments(companyId: number): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.baseUrl}/documents?company_id=${companyId}`
    );
  }
}