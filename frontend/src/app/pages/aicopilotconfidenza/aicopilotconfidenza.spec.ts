import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Aicopilotconfidenza } from './aicopilotconfidenza';

describe('Aicopilotconfidenza', () => {
  let component: Aicopilotconfidenza;
  let fixture: ComponentFixture<Aicopilotconfidenza>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Aicopilotconfidenza]
    })
    .compileComponents();

    fixture = TestBed.createComponent(Aicopilotconfidenza);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
