'use client';

import { useState } from 'react';
import Link from 'next/link';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

export function SifremiUnuttumFormu() {
  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: err } = await supabase.auth.resetPasswordForEmail(email.trim(), {
        redirectTo: `${window.location.origin}/sifre-sifirlama`,
      });
      if (err) throw err;
      setSent(true);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-1 flex-col lg:flex-row">

      {/* Sol — Form paneli */}
      <div className="flex w-full items-start justify-center px-6 py-10 lg:w-[480px] lg:shrink-0 lg:px-12 lg:py-14 xl:w-[520px]">
        <div className="w-full max-w-[420px]">

          {/* Geri linki */}
          <Link
            href="/giris"
            className="mb-6 inline-flex items-center gap-2 text-sm font-[700] text-muted transition-colors hover:text-textStrong"
          >
            <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="m15 18-6-6 6-6" />
            </svg>
            Giriş sayfasına dön
          </Link>

          {/* Başlık */}
          <div className="mb-8">
            <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10 text-primary">
              <svg viewBox="0 0 24 24" className="h-6 w-6 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                <path d="M7 11V7a5 5 0 0 1 10 0v4" />
              </svg>
            </div>
            <h1 className="text-[2rem] font-[900] leading-tight text-textStrong">
              Şifremi Unuttum
            </h1>
            <p className="mt-2 text-sm leading-relaxed text-muted">
              Hesabınıza bağlı e-posta adresinizi girin. Şifre sıfırlama bağlantısını anında göndereceğiz.
            </p>
          </div>

          {sent ? (
            /* Başarı durumu */
            <div className="space-y-5">
              <div className="flex flex-col items-center gap-4 rounded-2xl border border-success/25 bg-success/[0.08] px-6 py-8 text-center">
                <span className="flex h-14 w-14 items-center justify-center rounded-full bg-success/15 text-success">
                  <svg viewBox="0 0 24 24" className="h-7 w-7 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                    <polyline points="22 4 12 14.01 9 11.01" />
                  </svg>
                </span>
                <div>
                  <p className="text-base font-[900] text-success">E-posta gönderildi!</p>
                  <p className="mt-1 text-sm leading-relaxed text-muted">
                    <span className="font-[700] text-textStrong">{email}</span> adresine sıfırlama bağlantısı iletildi. Gelen kutunuzu (ve spam klasörünüzü) kontrol edin.
                  </p>
                </div>
              </div>

              <p className="text-center text-xs text-muted">
                E-posta gelmediyse{' '}
                <button
                  type="button"
                  onClick={() => { setSent(false); setEmail(''); }}
                  className="font-[800] text-primary hover:underline"
                >
                  tekrar dene
                </button>
              </p>

              <Link
                href="/giris"
                className="flex h-12 w-full items-center justify-center rounded-2xl border border-border bg-card text-sm font-[800] text-textStrong transition-colors hover:bg-cardAlt"
              >
                ← Giriş sayfasına dön
              </Link>
            </div>
          ) : (
            /* Form durumu */
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="mb-1.5 block text-sm font-[700] text-textStrong">E-posta</label>
                <div className="relative">
                  <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted">
                    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <rect x="2" y="4" width="20" height="16" rx="2" /><path d="m2 7 10 7 10-7" />
                    </svg>
                  </span>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    autoFocus
                    autoComplete="email"
                    placeholder="ornek@mail.com"
                    className="h-12 w-full rounded-2xl border border-border bg-bg pl-10 pr-4 text-sm text-text outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10"
                  />
                </div>
              </div>

              {error && (
                <div role="alert" className="rounded-2xl border border-danger/25 bg-danger/[0.08] px-4 py-3 text-sm font-[700] text-danger">
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="flex h-12 w-full items-center justify-center rounded-2xl bg-primary text-sm font-[900] text-white shadow-sm transition-all hover:opacity-90 disabled:opacity-60"
              >
                {loading ? 'Gönderiliyor…' : 'Sıfırlama Bağlantısı Gönder'}
              </button>

              <p className="text-center text-sm text-muted">
                Şifreni hatırladın mı?{' '}
                <Link href="/giris" className="font-[800] text-primary hover:underline">
                  Giriş yap
                </Link>
              </p>
            </form>
          )}

          {/* Güvenli rozet */}
          <div className="mt-8 flex items-center gap-3 rounded-2xl border border-border bg-cardAlt px-4 py-3">
            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary">
              <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /><polyline points="9 12 11 14 15 10" />
              </svg>
            </span>
            <div>
              <p className="text-sm font-[800] text-primary">Güvenli İşlem</p>
              <p className="text-xs text-muted">Bağlantı 1 saat içinde geçerliliğini yitirir.</p>
            </div>
          </div>

        </div>
      </div>

      {/* Sağ — Telefon görseli (sadece desktop) */}
      <div
        className="relative hidden flex-1 items-center justify-center overflow-hidden lg:flex"
        style={{ background: 'linear-gradient(135deg, #fff5f5 0%, #fef2f2 50%, #fff8f0 100%)' }}
      >
        <div className="pointer-events-none absolute right-[-80px] top-[-80px] h-[400px] w-[400px] rounded-full bg-primary/5" />
        <div className="pointer-events-none absolute bottom-[-60px] left-[-60px] h-[300px] w-[300px] rounded-full bg-primary/[0.04]" />
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/giris-gorsel.webp"
          alt="Yeedoy mobil uygulama"
          className="relative z-10 w-[380px] max-w-[80%] drop-shadow-2xl xl:w-[440px]"
          draggable={false}
        />
      </div>
    </div>
  );
}
