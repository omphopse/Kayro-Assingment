import { describe, expect, it } from 'vitest';
import { validEmail, validPhone } from './validation';

describe('client input validation', () => {
  it('accepts a conventional email and trims surrounding whitespace', () => {
    expect(validEmail('  person@example.com ')).toBe(true);
  });
  it('rejects a missing domain suffix', () => {
    expect(validEmail('person@example')).toBe(false);
  });
  it('accepts phone numbers with 7 to 15 digits regardless of formatting', () => {
    expect(validPhone('+91 98200 11111')).toBe(true);
    expect(validPhone('123456')).toBe(false);
    expect(validPhone('1234567890123456')).toBe(false);
  });
});
