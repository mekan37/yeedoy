import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { TwoFactorBanner } from '@/src/ui/bilesenler/two-factor-banner';

// next/link mock — jsdom ortaminda gercek Next.js router olmadigi icin
vi.mock('next/link', () => ({
  default: ({
    href,
    children,
    ...props
  }: {
    href: string;
    children: React.ReactNode;
    [key: string]: unknown;
  }) => React.createElement('a', { href, ...props }, children),
}));

describe('TwoFactorBanner', () => {
  it('2FA kapali oldugunda banner render edilir', () => {
    render(React.createElement(TwoFactorBanner, { hasTwoFactor: false }));
    expect(screen.getByRole('alert')).toBeInTheDocument();
  });

  it('2FA kapali oldugunda CTA butonu gorseldir', () => {
    render(React.createElement(TwoFactorBanner, { hasTwoFactor: false }));
    expect(screen.getByRole('link', { name: /2FA Aç/i })).toBeInTheDocument();
  });

  it('2FA kapali oldugunda CTA linki /profil/guvenlik adresine isaret eder', () => {
    render(React.createElement(TwoFactorBanner, { hasTwoFactor: false }));
    const link = screen.getByRole('link', { name: /2FA Aç/i });
    expect(link).toHaveAttribute('href', '/profil/guvenlik');
  });

  it('2FA acik oldugunda hicbir sey render edilmez', () => {
    const { container } = render(React.createElement(TwoFactorBanner, { hasTwoFactor: true }));
    expect(container.firstChild).toBeNull();
  });

  it('2FA acik oldugunda alert role mevcut degildir', () => {
    render(React.createElement(TwoFactorBanner, { hasTwoFactor: true }));
    expect(screen.queryByRole('alert')).not.toBeInTheDocument();
  });

  it('banner aria-label degeri dogrudur', () => {
    render(React.createElement(TwoFactorBanner, { hasTwoFactor: false }));
    expect(
      screen.getByRole('alert', { name: 'iki-faktor-dogrulama-uyarisi' }),
    ).toBeInTheDocument();
  });

  it('uyari ikon aria-hidden olarak isaretlenmistir', () => {
    render(React.createElement(TwoFactorBanner, { hasTwoFactor: false }));
    const svg = screen.getByRole('alert').querySelector('svg');
    expect(svg).toHaveAttribute('aria-hidden', 'true');
  });
});
