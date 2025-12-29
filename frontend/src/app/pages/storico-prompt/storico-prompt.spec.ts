import { ComponentFixture, TestBed } from '@angular/core/testing';

import { StoricoPrompt } from './storico-prompt';

describe('StoricoPrompt', () => {
  let component: StoricoPrompt;
  let fixture: ComponentFixture<StoricoPrompt>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [StoricoPrompt]
    })
    .compileComponents();

    fixture = TestBed.createComponent(StoricoPrompt);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
