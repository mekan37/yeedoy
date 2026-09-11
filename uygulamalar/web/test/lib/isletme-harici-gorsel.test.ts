import { NextRequest } from 'next/server';
import { describe, expect, it } from 'vitest';
// next.config.mjs JavaScript yapılandırmasıdır; projede ayrı bir deklarasyon dosyası yoktur.
// @ts-expect-error Yapılandırmanın çalışma zamanı çıktısı bu entegrasyon testinde doğrulanıyor.
import nextConfig from '../../next.config.mjs';
import { proxy } from '../../proxy';

describe('işletme harici görsel önizlemesi', () => {
  it('Hızlı Resim görsellerini Next Image ve tarayıcı CSP katmanlarında kabul eder', async () => {
    const remotePatterns = nextConfig.images?.remotePatterns ?? [];
    expect(remotePatterns).toEqual(expect.arrayContaining([
      expect.objectContaining({ protocol: 'https', hostname: 'i.hizliresim.com' }),
    ]));

    const response = await proxy(new NextRequest('https://localhost/yonetici/test'));
    expect(response.headers.get('content-security-policy')).toContain('https://i.hizliresim.com');
  });
});
