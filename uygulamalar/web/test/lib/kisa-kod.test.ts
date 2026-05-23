import { describe, expect, it } from 'vitest';
import { decodeBusinessCode, encodeBusinessCode } from '@/src/lib/kisa-kod';

describe('kisa-kod', () => {
  it('encodes and decodes a uuid deterministically', () => {
    const uuid = '123e4567-e89b-42d3-a456-426614174000';
    const code = encodeBusinessCode(uuid);

    expect(code).toBeTruthy();
    expect(decodeBusinessCode(code)).toBe(uuid);
  });

  it('returns null for invalid code payloads', () => {
    expect(decodeBusinessCode('invalid')).toBeNull();
  });
});
