'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

const CRITERIA = [
  { label: 'En az 8 karakter', test: (v: string) => v.length >= 8 },
  { label: 'Büyük harf',       test: (v: string) => /[A-Z]/.test(v) },
  { label: 'Küçük harf',       test: (v: string) => /[a-z]/.test(v) },
  { label: 'Rakam',            test: (v: string) => /\d/.test(v) },
  { label: 'Özel karakter',    test: (v: string) => /[^A-Za-z0-9]/.test(v) },
];

const STRENGTH_META = [
  { label: '',        bar: 'bg-border',   text: '' },
  { label: 'Çok Zayıf', bar: 'bg-danger', text: 'text-danger' },
  { label: 'Zayıf',  bar: 'bg-warning',  text: 'text-warning' },
  { label: 'Orta',   bar: 'bg-warning',  text: 'text-warning' },
  { label: 'İyi',    bar: 'bg-info',     text: 'text-info' },
  { label: 'Güçlü',  bar: 'bg-success',  text: 'text-success' },
];

export function SifreSifirlamaFormu() {
  const router = useRouter();
  const [password, setPassword]     = useState('');
  const [confirm, setConfirm]       = useState('');
  const [showPass, setShowPass]     = useState(false);
  const [loading, setLoading]       = useState(false);
  const [error, setError]           = useState('');
  const [done, setDone]             = useState(false);
  const [ready, setReady]           = useState(false);

  const strength = CRITERIA.filter((c) => c.test(password)).length;
  const meta     = STRENGTH_META[strength] ?? STRENGTH_META[0];

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') setReady(true);
    });
    return () => subscription.unsubscribe();
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (password !== confirm) { setError('Şifreler eşleşmiyor.'); return; }
    if (strength < 3) { setError('Daha güçlü bir şifre seçin.'); return; }
    setLoading(true);
    setError('');
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: err } = await supabase.auth.updateUser({ password });
      if (err) throw err;
      setDone(true);
      setTimeout(() => router.push('/giris'), 2500);
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
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /><polyline points="9 12 11 14 15 10" />
              </svg>
            </div>
            <h1 className="text-[2rem] font-[900] leading-tight text-textStrong">
              Yeni Şifre Belirle
            </h1>
            <p className="mt-2 text-sm leading-relaxed text-muted">
              Hesabınız için güçlü bir yeni şifre oluşturun.
            </p>
          </div>

          {done ? (
            /* Başarı */
            <div className="flex flex-col items-center gap-4 rounded-2xl border border-success/25 bg-success/[0.08] px-6 py-8 text-center">
              <span className="flex h-14 w-14 items-center justify-center rounded-full bg-success/15 text-success">
                <svg viewBox="0 0 24 24" className="h-7 w-7 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                  <polyline points="22 4 12 14.01 9 11.01" />
                </svg>
              </span>
              <div>
                <p className="text-base font-[900] text-success">Şifreniz güncellendi!</p>
                <p className="mt-1 text-sm text-muted">Giriş sayfasına yönlendiriliyorsunuz…</p>
              </div>
            </div>

          ) : !ready ? (
            /* Bağlantı bekleniyor */
            <div className="space-y-5">
              <div className="flex flex-col items-center gap-4 rounded-2xl border border-warning/25 bg-warning/[0.08] px-6 py-8 text-center">
                <span className="flex h-14 w-14 items-center justify-center rounded-full bg-warning/15 text-warning">
                  <svg viewBox="0 0 24 24" className="h-7 w-7 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />
                  </svg>
                </span>
                <div>
                  <p className="text-base font-[900] text-warning">Bağlantı bekleniyor</p>
                  <p className="mt-1 text-sm leading-relaxed text-muted">
                    E-postanızdaki sıfırlama bağlantısına tıklayarak bu sayfaya gelmeniz gerekiyor.
                  </p>
                </div>
              </div>
              <Link
                href="/sifremi-unuttum"
                className="flex h-12 w-full items-center justify-center rounded-2xl bg-primary text-sm font-[900] text-white shadow-sm transition-all hover:opacity-90"
              >
                Yeni bağlantı gönder
              </Link>
            </div>

          ) : (
            /* Şifre formu */
            <form onSubmit={handleSubmit} className="space-y-4">

              {/* Yeni şifre */}
              <div>
                <label className="mb-1.5 block text-sm font-[700] text-textStrong">Yeni Şifre</label>
                <div className="relative">
                  <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted">
                    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
                    </svg>
                  </span>
                  <input
                    type={showPass ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required autoFocus autoComplete="new-password"
                    placeholder="En az 8 karakter"
                    className="h-12 w-full rounded-2xl border border-border bg-bg pl-10 pr-11 text-sm text-text outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10"
                  />
                  <button
                    type="button"
                    aria-label={showPass ? 'Şifreyi gizle' : 'Şifreyi göster'}
                    onClick={() => setShowPass((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-textStrong"
                  >
                    {showPass
                      ? <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                      : <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    }
                  </button>
                </div>

                {/* Güç göstergesi */}
                {password.length > 0 && (
                  <div className="mt-2">
                    <div className="flex gap-1">
                      {CRITERIA.map((_, i) => (
                        <div
                          key={i}
                          className={`h-1.5 flex-1 rounded-full transition-all ${i < strength ? meta.bar : 'bg-border'}`}
                        />
                      ))}
                    </div>
                    <div className="mt-1.5 flex items-center justify-between">
                      <p className={`text-xs font-[700] ${meta.text}`}>{meta.label}</p>
                      <div className="flex gap-2">
                        {CRITERIA.map((c, i) => (
                          <span key={i} className={`text-[10px] font-[600] ${c.test(password) ? 'text-success' : 'text-border'}`}>
                            {['8+', 'A-Z', 'a-z', '0-9', '#'][i]}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* Şifre tekrar */}
              <div>
                <label className="mb-1.5 block text-sm font-[700] text-textStrong">Şifre Tekrar</label>
                <div className="relative">
                  <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted">
                    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
                    </svg>
                  </span>
                  <input
                    type={showPass ? 'text' : 'password'}
                    value={confirm}
                    onChange={(e) => setConfirm(e.target.value)}
                    required autoComplete="new-password"
                    placeholder="Şifrenizi tekrar girin"
                    className={`h-12 w-full rounded-2xl border bg-bg pl-10 pr-4 text-sm text-text outline-none transition focus:ring-2 focus:ring-primary/10 ${
                      confirm.length > 0
                        ? confirm === password
                          ? 'border-success focus:border-success'
                          : 'border-danger focus:border-danger'
                        : 'border-border focus:border-primary'
                    }`}
                  />
                  {confirm.length > 0 && (
                    <span className={`absolute right-3.5 top-1/2 -translate-y-1/2 ${confirm === password ? 'text-success' : 'text-danger'}`}>
                      {confirm === password
                        ? <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12" /></svg>
                        : <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                      }
                    </span>
                  )}
                </div>
              </div>

              {error && (
                <div role="alert" className="rounded-2xl border border-danger/25 bg-danger/[0.08] px-4 py-3 text-sm font-[700] text-danger">
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={loading || strength < 3}
                className="flex h-12 w-full items-center justify-center rounded-2xl bg-primary text-sm font-[900] text-white shadow-sm transition-all hover:opacity-90 disabled:opacity-60"
              >
                {loading ? 'Güncelleniyor…' : 'Şifreyi Güncelle'}
              </button>
            </form>
          )}

        </div>
      </div>

      {/* Sağ — Telefon görseli */}
      <div
        className="relative hidden flex-1 items-center justify-center overflow-hidden lg:flex"
        style={{ background: 'linear-gradient(135deg, #fff5f5 0%, #fef2f2 50%, #fff8f0 100%)' }}
      >
        <div className="pointer-events-none absolute right-[-80px] top-[-80px] h-[400px] w-[400px] rounded-full bg-primary/5" />
        <div className="pointer-events-none absolute bottom-[-60px] left-[-60px] h-[300px] w-[300px] rounded-full bg-primary/[0.04]" />
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/giris-gorsel.png"
          alt="Yeedoy mobil uygulama"
          className="relative z-10 w-[380px] max-w-[80%] drop-shadow-2xl xl:w-[440px]"
          draggable={false}
        />
      </div>
    </div>
  );
}
