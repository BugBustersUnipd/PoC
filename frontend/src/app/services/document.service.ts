import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class DocumentsService {
  private baseUrl = 'http://localhost:3000';

  constructor(private http: HttpClient) {}

  uploadDocument(file: File, companyId: number): Observable<any> {
    const formData = new FormData(); // va usato formData per inviare poi il file, se non venisse usato, il backend riceverebbe solo metadati del file come nome,tipo,dimensione e non il contenuto
    formData.append('document[original_file]', file); // qua il file deve essere definito così perchè documents_controller.rb lo necessita 

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