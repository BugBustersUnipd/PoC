import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ModificaGenerazione } from './modifica-generazione';

describe('ModificaGenerazione', () => {
  let component: ModificaGenerazione;
  let fixture: ComponentFixture<ModificaGenerazione>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ModificaGenerazione]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ModificaGenerazione);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
