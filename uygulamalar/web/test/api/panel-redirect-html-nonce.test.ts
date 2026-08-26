import { describe, expect, it } from 'vitest';
import { renderRedirectHtml as renderPanelHandoffRedirectHtml } from '@/app/auth/panel-handoff/route';
import { renderRedirectHtml as renderPanelDevirRedirectHtml } from '@/app/kimlik/panel-devir/route';

describe('panel-handoff redirect HTML nonce', () => {
  it('auto-redirect sırasında inline script nonce içeriyor', () => {
    const html = renderPanelHandoffRedirectHtml({
      title: 'Redirecting',
      message: 'Redirecting now.',
      destination: '/karekod/abc',
      ctaLabel: 'Open',
      nonce: 'test-nonce-value',
    });
    expect(html).toContain('<script nonce="test-nonce-value">');
  });

  it('autoRedirect false ise inline script hiç render edilmiyor', () => {
    const html = renderPanelHandoffRedirectHtml({
      title: 'Failed',
      message: 'Could not restore session.',
      destination: '/giris',
      ctaLabel: 'Open login',
      nonce: 'test-nonce-value',
      autoRedirect: false,
    });
    expect(html).not.toContain('<script');
  });
});

describe('panel-devir redirect HTML nonce', () => {
  it('auto-redirect sırasında inline script nonce içeriyor', () => {
    const html = renderPanelDevirRedirectHtml({
      title: 'Yonlendiriliyor',
      message: 'Simdi yonlendiriliyorsunuz.',
      destination: '/karekod/abc',
      ctaLabel: 'Ac',
      nonce: 'test-nonce-value',
    });
    expect(html).toContain('<script nonce="test-nonce-value">');
  });

  it('autoRedirect false ise inline script hiç render edilmiyor', () => {
    const html = renderPanelDevirRedirectHtml({
      title: 'Basarisiz',
      message: 'Oturum geri yuklenemedi.',
      destination: '/giris',
      ctaLabel: 'Giris ac',
      nonce: 'test-nonce-value',
      autoRedirect: false,
    });
    expect(html).not.toContain('<script');
  });
});
