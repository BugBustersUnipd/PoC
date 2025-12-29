import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AiCopilot } from './ai-copilot';

describe('AiCopilot', () => {
  let component: AiCopilot;
  let fixture: ComponentFixture<AiCopilot>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AiCopilot]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AiCopilot);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
