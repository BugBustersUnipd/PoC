import { TestBed } from '@angular/core/testing';

import { Conversations } from './conversations';

describe('Conversations', () => {
  let service: Conversations;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(Conversations);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
