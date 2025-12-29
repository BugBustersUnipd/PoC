import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Aicopilotanteprimadocumento } from './aicopilotanteprimadocumento';

describe('Aicopilotanteprimadocumento', () => {
  let component: Aicopilotanteprimadocumento;
  let fixture: ComponentFixture<Aicopilotanteprimadocumento>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Aicopilotanteprimadocumento]
    })
    .compileComponents();

    fixture = TestBed.createComponent(Aicopilotanteprimadocumento);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
