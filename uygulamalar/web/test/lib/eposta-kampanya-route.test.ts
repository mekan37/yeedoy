import { describe, it, expect } from 'vitest';
import { epostaKampanyaGovdesi } from '@/app/sunucu/sahip/eposta-kampanya/sema';
import { stripHtml, escapeHtml } from '@/app/sunucu/sahip/eposta-kampanya/metin-temizle';

describe('epostaKampanyaGovdesi', () => {
  it('geçerli bir gövdeyi kabul eder', () => {
    const result = epostaKampanyaGovdesi.safeParse({
      businessId: '11111111-1111-4111-8111-111111111111',
      subject: 'Yeni Kampanya',
      body: 'Merhaba, size özel bir teklifimiz var.',
      targetSegment: 'tag:VIP',
    });
    expect(result.success).toBe(true);
  });

  it('boş subject reddedilir', () => {
    const result = epostaKampanyaGovdesi.safeParse({
      businessId: '11111111-1111-4111-8111-111111111111',
      subject: '',
      body: 'Merhaba',
      targetSegment: 'all_followers',
    });
    expect(result.success).toBe(false);
  });

  it('geçersiz businessId (uuid değil) reddedilir', () => {
    const result = epostaKampanyaGovdesi.safeParse({
      businessId: 'not-a-uuid',
      subject: 'Test',
      body: 'Merhaba',
      targetSegment: 'all_followers',
    });
    expect(result.success).toBe(false);
  });
});

describe('stripHtml + escapeHtml', () => {
  it('çift kodlanmış (entity-encoded) etiketleri diriltmeden temizler', () => {
    const input = '&amp;lt;script&amp;gt;alert(1)&amp;lt;/script&amp;gt;';
    const stripped = stripHtml(input);
    const output = escapeHtml(stripped);

    expect(output).not.toContain('<script>');
    expect(output).not.toMatch(/<script[\s>]/i);
    expect(output).not.toContain('<');
    expect(output).not.toContain('>');
  });

  it('düz metindeki & ve < karakterlerini şablona gömülürken kaçırır', () => {
    // "<" burada kapanan bir ">" olmadığı için etiket gibi algılanıp
    // strip aşamasında silinmez — düz metin olarak kalır ve escapeHtml
    // aşamasında güvenli biçimde kaçılması beklenir.
    const input = 'Ürünler %20 & üzeri indirimde, 5 < 10 gün kaldı';
    const stripped = stripHtml(input);
    const output = escapeHtml(stripped);

    expect(output).toBe('Ürünler %20 &amp; üzeri indirimde, 5 &lt; 10 gün kaldı');
  });

  it('normal (tek kodlanmış) HTML etiketlerini olağan şekilde temizler', () => {
    const input = '<b>Merhaba</b> <script>alert(1)</script> dünya';
    const stripped = stripHtml(input);
    expect(stripped).toBe('Merhaba alert(1) dünya');
  });
});
