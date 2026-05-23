'use client';

import { useEffect, useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';
import { TR_ILLER, TR_ILCELER } from '@/src/lib/tr-ilceler';
import { toast } from '@/src/lib/toast-deposu';
import { GoogleIcon, AppleIcon } from './giris-ikon';
import { getPasswordStrength, hataMesaji, formatPhone, PASSWORD_CRITERIA } from './giris-yardimci';

type Mode = 'giris' | 'kayit';



type Props = {
  redirectTo: string | null;
  panelLoginUrl?: string | null;
};

export function GirisFormu({ redirectTo, panelLoginUrl }: Props) {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>('giris');
  const [displayName, setDisplayName] = useState('');
  const [phone, setPhone] = useState('');
  const [city, setCity] = useState('');
  const [district, setDistrict] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isPending, startTransition] = useTransition();
  const [oAuthProvider, setOAuthProvider] = useState<'google' | 'apple' | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [acceptedTerms, setAcceptedTerms] = useState(false);
  const [acceptedPrivacy, setAcceptedPrivacy] = useState(false);

  const districts = city ? (TR_ILCELER[city] ?? []) : [];

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
    setOAuthProvider(provider);
    const supabase = createSupabaseBrowserClient();
    const callbackUrl = new URL('/auth/callback', window.location.origin);
    if (redirectTo) callbackUrl.searchParams.set('redirect', redirectTo);
    await supabase.auth.signInWithOAuth({
      provider,
      options: { redirectTo: callbackUrl.toString() },
    });
    setOAuthProvider(null);
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (mode === 'kayit' && password !== confirmPassword) {
      setError('Şifreler eşleşmiyor.');
      return;
    }

    if (mode === 'kayit' && getPasswordStrength(password).level < 3) {
      setError('Şifre tüm güvenlik kriterlerini karşılamıyor. Lütfen daha güçlü bir şifre oluşturun.');
      return;
    }

    if (mode === 'kayit' && !displayName.trim()) {
      setError('Ad Soyad alanı zorunludur.');
      return;
    }

    if (mode === 'kayit' && (!acceptedTerms || !acceptedPrivacy)) {
      setError('Devam etmek için Kullanım Şartları ve Gizlilik Politikasını kabul etmelisiniz.');
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
            data: {
              display_name: displayName.trim(),
              ...(city     && { city }),
              ...(district && { district }),
              ...(phone.trim() && { phone: phone.trim() }),
            },
          },
        });
        if (signUpError) {
          setError(hataMesaji(signUpError));
          return;
        }
        // E-posta onayı kapalıysa session anında gelir → profil oluştur ve yönlendir
        if (signUpData.session) {
          const { error: profileError } = await (supabase as any).from('user_profiles').insert({
            user_id: signUpData.session.user.id,
            display_name: displayName.trim(),
            ...(city        && { city }),
            ...(district    && { district }),
            ...(phone.trim() && { phone: phone.trim() }),
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
    setPhone('');
    setCity('');
    setDistrict('');
    setAcceptedTerms(false);
    setAcceptedPrivacy(false);
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
              disabled={isPending || oAuthProvider !== null}
              className="flex h-12 w-full items-center justify-center gap-3 rounded-2xl border border-border bg-card text-sm font-[700] text-textStrong shadow-sm transition-colors hover:bg-cardAlt disabled:opacity-50"
            >
              {oAuthProvider === 'google' ? (
                <span className="h-4 w-4 animate-spin rounded-full border-2 border-border border-t-primary" />
              ) : (
                <GoogleIcon />
              )}
              Google ile {mode === 'giris' ? 'giriş yap' : 'kayıt ol'}
            </button>

            <button
              type="button"
              onClick={() => void handleOAuth('apple')}
              disabled={isPending || oAuthProvider !== null}
              className="flex h-12 w-full items-center justify-center gap-3 rounded-2xl bg-[#000] text-sm font-[700] text-white shadow-sm transition-colors hover:bg-[#1a1a1a] disabled:opacity-50"
            >
              {oAuthProvider === 'apple' ? (
                <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
              ) : (
                <AppleIcon />
              )}
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
          <form onSubmit={handleSubmit} className="space-y-4" aria-describedby={error ? 'form-error' : undefined}>

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
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  autoComplete={mode === 'giris' ? 'current-password' : 'new-password'}
                  placeholder="••••••••"
                  className="h-12 w-full rounded-2xl border border-border bg-bg pl-4 pr-11 text-sm text-text outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10"
                />
                <button
                  type="button"
                  aria-label={showPassword ? 'Şifreyi gizle' : 'Şifreyi göster'}
                  onClick={() => setShowPassword((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-textStrong"
                >
                  {showPassword ? (
                    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                  ) : (
                    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  )}
                </button>
              </div>

              {/* Şifre güç göstergesi — sadece kayıt modunda */}
              {mode === 'kayit' && password.length > 0 && (() => {
                const strength = getPasswordStrength(password);
                return (
                  <div className="mt-3 space-y-2">
                    {/* Renkli bar */}
                    <div className="flex items-center gap-2">
                      <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-border">
                        <div
                          className={`h-full rounded-full transition-all duration-300 ${strength.color} ${strength.width}`}
                        />
                      </div>
                      <span className={`text-xs font-[700] ${
                        strength.level === 3 ? 'text-green-600' :
                        strength.level === 2 ? 'text-orange-500' :
                        strength.level === 1 ? 'text-yellow-600' : 'text-red-500'
                      }`}>
                        {strength.label}
                      </span>
                    </div>
                    {/* Kriter listesi */}
                    <ul className="space-y-1">
                      {PASSWORD_CRITERIA.map((c) => {
                        const ok = c.test(password);
                        return (
                          <li key={c.id} className={`flex items-center gap-1.5 text-xs font-[600] ${ok ? 'text-green-600' : 'text-muted'}`}>
                            <span className="shrink-0">{ok ? '✓' : '✗'}</span>
                            {c.label}
                          </li>
                        );
                      })}
                    </ul>
                  </div>
                );
              })()}
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

            {/* Telefon, il, ilçe — sadece kayıt modunda */}
            {mode === 'kayit' && (
              <>
                <div>
                  <label className="mb-1.5 block text-xs font-[800] uppercase tracking-[0.16em] text-muted">
                    Telefon <span className="font-[500] normal-case tracking-normal text-muted/60">(opsiyonel)</span>
                  </label>
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => {
                      const digits = e.target.value.replace(/\D/g, '').slice(0, 11);
                      let fmt = digits;
                      if (digits.length > 4) fmt = `${digits.slice(0, 4)} ${digits.slice(4)}`;
                      if (digits.length > 7) fmt = `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7)}`;
                      if (digits.length > 9) fmt = `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7, 9)} ${digits.slice(9, 11)}`;
                      setPhone(fmt);
                    }}
                    autoComplete="tel"
                    placeholder="0532 123 45 67"
                    maxLength={14}
                    className="h-12 w-full rounded-2xl border border-border bg-bg px-4 text-sm text-text outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  {/* İl */}
                  <div>
                    <label className="mb-1.5 block text-xs font-[800] uppercase tracking-[0.16em] text-muted">
                      İl <span className="font-[500] normal-case tracking-normal text-muted/60">(opsiyonel)</span>
                    </label>
                    <select
                      value={city}
                      onChange={(e) => { setCity(e.target.value); setDistrict(''); }}
                      className="h-12 w-full rounded-2xl border border-border bg-bg px-4 text-sm text-text outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10 appearance-none cursor-pointer"
                    >
                      <option value="">İl seçin</option>
                      {TR_ILLER.map((il) => (
                        <option key={il} value={il}>{il}</option>
                      ))}
                    </select>
                  </div>

                  {/* İlçe */}
                  <div>
                    <label className="mb-1.5 block text-xs font-[800] uppercase tracking-[0.16em] text-muted">
                      İlçe <span className="font-[500] normal-case tracking-normal text-muted/60">(opsiyonel)</span>
                    </label>
                    <select
                      value={district}
                      onChange={(e) => setDistrict(e.target.value)}
                      disabled={!city}
                      className="h-12 w-full rounded-2xl border border-border bg-bg px-4 text-sm text-text outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/10 appearance-none cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
                    >
                      <option value="">İlçe seçin</option>
                      {districts.map((d) => (
                        <option key={d} value={d}>{d}</option>
                      ))}
                    </select>
                  </div>
                </div>
              </>
            )}

            {/* Kullanıcı sözleşmesi onay kutuları — sadece kayıt modunda */}
            {mode === 'kayit' && (
              <div className="space-y-3 rounded-2xl border border-border bg-cardAlt px-4 py-4">
                <label className="flex cursor-pointer items-start gap-3">
                  <input
                    type="checkbox"
                    checked={acceptedTerms}
                    onChange={(e) => setAcceptedTerms(e.target.checked)}
                    className="mt-0.5 h-4 w-4 shrink-0 cursor-pointer accent-primary"
                    required
                  />
                  <span className="text-sm text-textStrong">
                    <a href="/yasal/terms" target="_blank" rel="noopener noreferrer" className="font-[800] text-primary underline-offset-2 hover:underline">
                      Kullanım Şartları
                    </a>
                    &apos;nı okudum ve kabul ediyorum.{' '}
                    <span className="text-danger">*</span>
                  </span>
                </label>
                <label className="flex cursor-pointer items-start gap-3">
                  <input
                    type="checkbox"
                    checked={acceptedPrivacy}
                    onChange={(e) => setAcceptedPrivacy(e.target.checked)}
                    className="mt-0.5 h-4 w-4 shrink-0 cursor-pointer accent-primary"
                    required
                  />
                  <span className="text-sm text-textStrong">
                    <a href="/yasal/privacy" target="_blank" rel="noopener noreferrer" className="font-[800] text-primary underline-offset-2 hover:underline">
                      Gizlilik Politikası
                    </a>
                    &apos;nı ve{' '}
                    <a href="/yasal/yorum-politikasi" target="_blank" rel="noopener noreferrer" className="font-[800] text-primary underline-offset-2 hover:underline">
                      Yorum Politikası
                    </a>
                    &apos;nı okudum, kabul ediyorum.{' '}
                    <span className="text-danger">*</span>
                  </span>
                </label>
              </div>
            )}

            {error && (
              <div
                id="form-error"
                role="alert"
                aria-live="polite"
                className="rounded-2xl border border-danger/25 bg-danger/[0.08] px-4 py-3 text-sm font-[700] text-danger"
              >
                {error}
              </div>
            )}

            {success && (
              <div
                id="form-success"
                role="status"
                aria-live="polite"
                className="rounded-2xl border border-success/25 bg-success/[0.10] px-4 py-3 text-sm font-[700] text-success"
              >
                {success}
              </div>
            )}

            <button
              type="submit"
              disabled={isPending || (mode === 'kayit' && (!acceptedTerms || !acceptedPrivacy))}
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

