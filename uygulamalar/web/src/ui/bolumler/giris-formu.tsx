'use client';

import { useEffect, useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';

type Mode = 'giris' | 'kayit';

type Props = {
  redirectTo: string | null;
  panelLoginUrl?: string | null;
};

export function GirisFormu({ redirectTo, panelLoginUrl }: Props) {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>('giris');
  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    let ignore = false;
    async function syncExistingSession() {
      const supabase = createSupabaseBrowserClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (ignore || !session) return;
      if (redirectTo) {
        router.replace(redirectTo);
      } else {
        const res = await fetch('/sunucu/kimlik/rol-yonlendirme');
        const data = await res.json().catch(() => null) as { redirectTo?: string } | null;
        router.replace(data?.redirectTo ?? '/');
      }
      router.refresh();
    }
    void syncExistingSession();
    return () => { ignore = true; };
  }, [redirectTo, router]);

  async function handleOAuth(provider: 'google' | 'apple') {
    const supabase = createSupabaseBrowserClient();
    const callbackUrl = new URL('/auth/callback', window.location.origin);
    if (redirectTo) callbackUrl.searchParams.set('redirect', redirectTo);
    await supabase.auth.signInWithOAuth({
      provider,
      options: { redirectTo: callbackUrl.toString() },
    });
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (mode === 'kayit' && password !== confirmPassword) {
      setError('Şifreler eşleşmiyor.');
      return;
    }

    if (mode === 'kayit' && !displayName.trim()) {
      setError('Ad Soyad alanı zorunludur.');
      return;
    }

    startTransition(async () => {
      if (mode === 'giris') {
        const body: Record<string, string> = { email: email.trim(), password };
        if (redirectTo) body.redirectTo = redirectTo;
        const response = await fetch('/sunucu/kimlik/giris', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body),
        });
        const result = await response.json().catch(() => null) as { redirectTo?: string; error?: string } | null;
        if (!response.ok) {
          setError(result?.error ?? 'Giriş yapılamadı. E-posta ve şifrenizi kontrol edin.');
          return;
        }
        window.location.assign(result?.redirectTo ?? redirectTo ?? '/');
        router.refresh();
      } else {
        const supabase = createSupabaseBrowserClient();
        const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
          email: email.trim(),
          password,
          options: {
            emailRedirectTo: `${window.location.origin}/auth/callback${redirectTo ? `?redirect=${encodeURIComponent(redirectTo)}` : ''}`,
            data: { display_name: displayName.trim() },
          },
        });
        if (signUpError) {
          setError(signUpError.message);
          return;
        }
        // E-posta onayı kapalıysa session anında gelir → profil oluştur ve yönlendir
        if (signUpData.session) {
          const { error: profileError } = await (supabase as any).from('user_profiles').insert({
            user_id: signUpData.session.user.id,
            display_name: displayName.trim(),
          }) as { error: { code?: string; message?: string } | null };
          if (profileError && profileError.code !== '23505') {
            // 23505 = unique violation (profil zaten var) → görmezden gel
            setError('Hesap oluşturuldu ancak profil kaydedilemedi. Giriş yapabilirsiniz.');
            return;
          }
          window.location.assign(redirectTo ?? '/');
          router.refresh();
          return;
        }
        setSuccess('Doğrulama e-postası gönderildi. Gelen kutunuzu kontrol edin.');
      }
    });
  }

  function switchMode(next: Mode) {
    setMode(next);
    setError('');
    setSuccess('');
  }

  return (
    <div className="flex min-h-screen w-full">
      {/* Sol panel — sadece desktop */}
      <div
        className="hidden md:flex md:w-5/12 lg:w-[42%] flex-col justify-between p-12"
        style={{
          background:
            'linear-gradient(145deg, var(--yd-color-primary-deep) 0%, var(--yd-color-primary) 55%, var(--yd-color-primary-strong) 100%)',
        }}
      >
        <YeedoyLogo size={40} textColor="white" />

        <div>
          <h2 className="text-[2.6rem] font-[900] leading-[1.1] text-white">
            Yakınındaki<br />lezzetleri<br />keşfet
          </h2>
          <p className="mt-5 text-base leading-relaxed text-white/70">
            Gerçek fiyatlar, topluluk yorumları ve akıllı keşif tek platformda.
          </p>

          <div className="mt-10 space-y-3.5">
            {[
              { icon: '🍽', label: 'Binlerce restoran ve kafe' },
              { icon: '💰', label: 'Güncel menü fiyatları' },
              { icon: '⭐', label: 'Güvenilir yorumlar' },
              { icon: '🗺', label: 'Konum bazlı keşif' },
            ].map((item) => (
              <div key={item.label} className="flex items-center gap-3">
                <span className="text-xl">{item.icon}</span>
                <span className="text-sm font-[600] text-white/90">{item.label}</span>
              </div>
            ))}
          </div>
        </div>

        <p className="text-xs text-white/40">© {new Date().getFullYear()} Yeedoy. Tüm hakları saklıdır.</p>
      </div>

      {/* Sağ panel — form */}
      <div className="flex flex-1 items-center justify-center bg-bg px-5 py-10 sm:px-8">
        <div className="w-full max-w-[420px]">

          {/* Mobil logo */}
          <div className="mb-8 flex flex-col items-center md:hidden">
            <YeedoyLogo size={40} />
            <p className="mt-2 text-sm text-muted">Yakınındaki lezzetleri keşfet</p>
          </div>

          {/* Başlık */}
          <div className="mb-7">
            <h1 className="text-2xl font-[900] text-textStrong">
              {mode === 'giris' ? 'Tekrar hoş geldiniz' : 'Hesap oluştur'}
            </h1>
            <p className="mt-1 text-sm text-muted">
              {mode === 'giris'
                ? 'Hesabına giriş yap, keşfetmeye devam et'
                : 'Ücretsiz hesap oluştur, hemen başla'}
            </p>
          </div>

          {/* Sosyal butonlar */}
          <div className="space-y-3">
            <button
              type="button"
              onClick={() => void handleOAuth('google')}
              disabled={isPending}
              className="flex h-12 w-full items-center justify-center gap-3 rounded-2xl border border-border bg-card text-sm font-[700] text-textStrong shadow-sm transition-colors hover:bg-cardAlt disabled:opacity-50"
            >
              <GoogleIcon />
              Google ile {mode === 'giris' ? 'giriş yap' : 'kayıt ol'}
            </button>

            <button
              type="button"
              onClick={() => void handleOAuth('apple')}
              disabled={isPending}
              className="flex h-12 w-full items-center justify-center gap-3 rounded-2xl bg-[#000] text-sm font-[700] text-white shadow-sm transition-colors hover:bg-[#1a1a1a] disabled:opacity-50"
            >
              <AppleIcon />
              Apple ile {mode === 'giris' ? 'giriş yap' : 'kayıt ol'}
            </button>
          </div>

          {/* Ayraç */}
          <div className="my-6 flex items-center gap-3">
            <div className="h-px flex-1 bg-border" />
            <span className="text-xs font-[600] text-muted">veya e-posta ile</span>
            <div className="h-px flex-1 bg-border" />
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">

            {/* Ad Soyad — sadece kayıt modunda */}
            {mode === 'kayit' && (
              <div>
                <label className="mb-1.5 block text-xs font-[800] uppercase tracking-[0.16em] text-muted">
                  Ad Soyad
                </label>
                <input
                  type="text"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  required
                  autoComplete="name"
                  placeholder="Adınız Soyadınız"
                  maxLength={60}
                  className="h-12 w-full rounded-2xl border border-border bg-bg px-4 text-sm text-text outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10"
                />
              </div>
            )}

            <div>
              <label className="mb-1.5 block text-xs font-[800] uppercase tracking-[0.16em] text-muted">
                E-posta
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                placeholder="ornek@mail.com"
                className="h-12 w-full rounded-2xl border border-border bg-bg px-4 text-sm text-text outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10"
              />
            </div>

            <div>
              <div className="mb-1.5 flex items-center justify-between">
                <label className="text-xs font-[800] uppercase tracking-[0.16em] text-muted">
                  Şifre
                </label>
                {mode === 'giris' && (
                  <Link href="/sifremi-unuttum" className="text-xs font-[700] text-primary hover:underline">
                    Şifremi unuttum
                  </Link>
                )}
              </div>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete={mode === 'giris' ? 'current-password' : 'new-password'}
                placeholder="••••••••"
                className="h-12 w-full rounded-2xl border border-border bg-bg px-4 text-sm text-text outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10"
              />
            </div>

            {mode === 'kayit' && (
              <div>
                <label className="mb-1.5 block text-xs font-[800] uppercase tracking-[0.16em] text-muted">
                  Şifre tekrar
                </label>
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                  autoComplete="new-password"
                  placeholder="••••••••"
                  className="h-12 w-full rounded-2xl border border-border bg-bg px-4 text-sm text-text outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10"
                />
              </div>
            )}

            {error && (
              <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/40 dark:bg-red-950/30 dark:text-red-400">
                {error}
              </div>
            )}

            {success && (
              <div className="rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700 dark:border-green-900/40 dark:bg-green-950/30 dark:text-green-400">
                {success}
              </div>
            )}

            <button
              type="submit"
              disabled={isPending}
              className="flex h-12 w-full items-center justify-center rounded-2xl bg-primary text-sm font-[900] text-white shadow-sm transition-colors hover:opacity-90 disabled:opacity-60"
            >
              {isPending
                ? mode === 'giris' ? 'Giriş yapılıyor…' : 'Hesap oluşturuluyor…'
                : mode === 'giris' ? 'Giriş yap' : 'Hesap oluştur'}
            </button>
          </form>

          {/* Mod değiştirme */}
          <p className="mt-6 text-center text-sm text-muted">
            {mode === 'giris' ? (
              <>
                Hesabın yok mu?{' '}
                <button
                  type="button"
                  onClick={() => switchMode('kayit')}
                  className="font-[800] text-primary hover:underline"
                >
                  Kayıt ol
                </button>
              </>
            ) : (
              <>
                Zaten hesabın var mı?{' '}
                <button
                  type="button"
                  onClick={() => switchMode('giris')}
                  className="font-[800] text-primary hover:underline"
                >
                  Giriş yap
                </button>
              </>
            )}
          </p>

          {/* Panel linki */}
          {panelLoginUrl && mode === 'giris' && (
            <div className="mt-5 rounded-2xl border border-border bg-cardAlt p-4 text-center">
              <p className="text-xs text-muted">İşletme paneli için ayrı giriş</p>
              <Link
                href={panelLoginUrl}
                className="mt-0.5 inline-block text-sm font-[800] text-primary hover:underline"
              >
                Panel girişine git →
              </Link>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ── İkonlar ───────────────────────────────────────────────────────────────────

function GoogleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="#4285F4"
        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
      />
      <path
        fill="#34A853"
        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
      />
      <path
        fill="#FBBC05"
        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
      />
      <path
        fill="#EA4335"
        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
      />
    </svg>
  );
}

function AppleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="white" aria-hidden="true">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
    </svg>
  );
}
