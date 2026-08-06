import { describe, it, expect } from 'vitest';
import { ticketMatchesTab, formatTicketNo } from '@/app/sahip/destek/destek-yardimcilari';

describe('ticketMatchesTab', () => {
  it('tumu her durumu kapsar', () => {
    expect(ticketMatchesTab('open', 'tumu')).toBe(true);
    expect(ticketMatchesTab('closed', 'tumu')).toBe(true);
  });

  it('acik sadece open durumunu kapsar', () => {
    expect(ticketMatchesTab('open', 'acik')).toBe(true);
    expect(ticketMatchesTab('in_progress', 'acik')).toBe(false);
  });

  it('beklemede sadece in_progress durumunu kapsar', () => {
    expect(ticketMatchesTab('in_progress', 'beklemede')).toBe(true);
    expect(ticketMatchesTab('open', 'beklemede')).toBe(false);
  });

  it('cozuldu resolved ve closed durumlarını kapsar', () => {
    expect(ticketMatchesTab('resolved', 'cozuldu')).toBe(true);
    expect(ticketMatchesTab('closed', 'cozuldu')).toBe(true);
    expect(ticketMatchesTab('open', 'cozuldu')).toBe(false);
  });
});

describe('formatTicketNo', () => {
  it('id\'nin ilk 8 karakterini # ile büyük harfli döner', () => {
    expect(formatTicketNo('abcdef12-3456-7890-abcd-ef1234567890')).toBe('#ABCDEF12');
  });
});
