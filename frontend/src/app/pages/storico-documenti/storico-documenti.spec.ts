import { ComponentFixture, TestBed } from '@angular/core/testing';

import { StoricoDocumenti } from './storico-documenti';

describe('StoricoDocumenti', () => {
  let component: StoricoDocumenti;
  let fixture: ComponentFixture<StoricoDocumenti>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [StoricoDocumenti]
    })
    .compileComponents();

    fixture = TestBed.createComponent(StoricoDocumenti);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
