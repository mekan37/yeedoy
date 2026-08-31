'use client';

import { useEffect, useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { GoogleIcon, AppleIcon } from './giris-ikon';
import { hataMesaji } from './giris-yardimci';

type Mode = 'giris' | 'kayit';

const COUNTRY_CODES = [
  { code: '+90', flag: '🇹🇷', label: 'TR' },
  { code: '+1',  flag: '🇺🇸', label: 'US' },
  { code: '+44', flag: '🇬🇧', label: 'GB' },
  { code: '+49', flag: '🇩🇪', label: 'DE' },
  { code: '+31', flag: '🇳🇱', label: 'NL' },
  { code: '+33', flag: '🇫🇷', label: 'FR' },
  { code: '+41', flag: '🇨🇭', label: 'CH' },
  { code: '+43', flag: '🇦🇹', label: 'AT' },
];

type Props = {
  redirectTo: string | null;
  panelLoginUrl?: string | null;
  initialTab?: Mode;
};

export function GirisFormu({ redirectTo, panelLoginUrl, initialTab = 'giris' }: Props) {
  const router = useRouter();
  // mode is derived from the URL (initialTab prop) — tab switching uses Link navigation
  const mode: Mode = initialTab;

  // Giriş alanları
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(false);

  // Kayıt alanları
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName]   = useState('');
  const [phone, setPhone]         = useState('');
  const [countryCode, setCountryCode] = useState('+90');
  const [showCodePicker, setShowCodePicker] = useState(false);
  const [birthDate, setBirthDate] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [acceptedTerms, setAcceptedTerms] = useState(false);

  const [error, setError]     = useState('');
  const [success, setSuccess] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [isPending, startTransition] = useTransition();
  const [oAuthProvider, setOAuthProvider] = useState<'google' | 'apple' | null>(null);
  const [showPassword, setShowPassword]   = useState(false);
  const [yasalModal, setYasalModal]       = useState<'terms' | 'privacy' | null>(null);

  useEffect(() => {
    try {
      const saved = localStorage.getItem('yd_beni_hatirla');
      // localStorage okuması UI dışı bir kaynaktan senkronizasyon.
      // eslint-disable-next-line react-hooks/set-state-in-effect
      if (saved) { setEmail(saved); setRememberMe(true); }
    } catch { /* ignore */ }
  }, []);

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
    await supabase.auth.signInWithOAuth({ provider, options: { redirectTo: callbackUrl.toString() } });
    setOAuthProvider(null);
  }

  function validateField(field: 'firstName' | 'email' | 'password' | 'confirmPassword', values: { firstName: string; email: string; password: string; confirmPassword: string }): string {
    switch (field) {
      case 'firstName':
        return mode === 'kayit' && !values.firstName.trim() ? 'Ad alanı zorunludur.' : '';
      case 'email':
        if (!values.email.trim()) return mode === 'giris' ? 'E-posta veya telefon numarası zorunludur.' : 'E-posta adresi zorunludur.';
        if (mode === 'kayit' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(values.email.trim())) return 'Lütfen geçerli bir e-posta adresi girin.';
        return '';
      case 'password':
        if (!values.password) return 'Şifre zorunludur.';
        if (mode === 'kayit' && values.password.length < 8) return 'Şifre en az 8 karakter olmalıdır.';
        return '';
      case 'confirmPassword':
        return mode === 'kayit' && values.password !== values.confirmPassword ? 'Şifreler eşleşmiyor.' : '';
      default:
        return '';
    }
  }

  function handleFieldBlur(field: 'firstName' | 'email' | 'password' | 'confirmPassword') {
    const msg = validateField(field, { firstName, email, password, confirmPassword });
    setFieldErrors((prev) => ({ ...prev, [field]: msg }));
  }

  function clearFieldError(field: string) {
    setFieldErrors((prev) => (prev[field] ? { ...prev, [field]: '' } : prev));
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setSuccess('');

    const values = { firstName, email, password, confirmPassword };
    const fields: Array<'firstName' | 'email' | 'password' | 'confirmPassword'> = mode === 'kayit'
      ? ['firstName', 'email', 'password', 'confirmPassword']
      : ['email', 'password'];
    const errs: Record<string, string> = {};
    for (const field of fields) {
      const msg = validateField(field, values);
      if (msg) errs[field] = msg;
    }
    if (Object.keys(errs).length > 0) {
      setFieldErrors((prev) => ({ ...prev, ...errs }));
      setError(errs[fields.find((f) => errs[f]) ?? fields[0]]);
      return;
    }
    if (mode === 'kayit' && !acceptedTerms) {
      setError('Devam etmek için Kullanım Şartları ve Gizlilik Politikası\'nı kabul etmelisiniz.');
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
          setError(hataMesaji(result?.error ?? 'auth_failed'));
          return;
        }
        try {
          if (rememberMe) {
            localStorage.setItem('yd_beni_hatirla', email.trim());
          } else {
            localStorage.removeItem('yd_beni_hatirla');
          }
        } catch { /* ignore */ }
        window.location.assign(result?.redirectTo ?? redirectTo ?? '/');
        router.refresh();
      } else {
        const supabase = createSupabaseBrowserClient();
        const displayName = `${firstName.trim()} ${lastName.trim()}`.trim();
        const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
          email: email.trim(),
          password,
          options: {
            emailRedirectTo: `${window.location.origin}/auth/callback${redirectTo ? `?redirect=${encodeURIComponent(redirectTo)}` : ''}`,
            data: {
              display_name: displayName,
              first_name: firstName.trim(),
              last_name: lastName.trim(),
              ...(phone.trim() && { phone: `${countryCode}${phone.trim()}` }),
              ...(birthDate    && { birth_date: birthDate }),
            },
          },
        });
        if (signUpError) { setError(hataMesaji(signUpError)); return; }
        if (signUpData.session) {
          const { error: profileError } = await (supabase as any).from('user_profiles').insert({
            user_id: signUpData.session.user.id,
            display_name: displayName,
            ...(phone.trim() && { phone: `${countryCode}${phone.trim()}` }),
          }) as { error: { code?: string } | null };
          if (profileError && profileError.code !== '23505') {
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


  return (
    <main>
      {/* Ana içerik — 2 sütun */}
      <div className="flex flex-1 flex-col lg:flex-row">

        {/* Sol — Form paneli */}
        <div className="flex w-full items-start justify-center px-6 py-10 lg:w-[480px] lg:shrink-0 lg:px-12 lg:py-14 xl:w-[520px]">
          <div className="w-full max-w-[420px]">

            {/* Başlık */}
            <div className="mb-7">
              <h1 className="text-[2rem] font-black leading-tight text-textStrong">
                Hoş geldin! 👋
              </h1>
              <p className="mt-2 text-sm leading-relaxed text-muted">
                Yeedoy&apos;a giriş yaparak lezzetli keşiflere başlayabilirsin.
              </p>
            </div>

            {/* Sekme geçişi */}
            <div className="mb-7 flex border-b border-border">
              <Link
                href="/giris"
                className={`flex items-center gap-2 px-1 pb-3 text-sm font-extrabold transition-colors ${
                  mode === 'giris' ? 'border-b-2 border-primary text-primary' : 'text-muted hover:text-textStrong'
                }`}
                style={{ marginBottom: '-1px' }}
              >
                <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
                </svg>
                Giriş Yap
              </Link>
              <Link
                href="/giris?tab=kayit"
                className={`ml-6 flex items-center gap-2 px-1 pb-3 text-sm font-extrabold transition-colors ${
                  mode === 'kayit' ? 'border-b-2 border-primary text-primary' : 'text-muted hover:text-textStrong'
                }`}
                style={{ marginBottom: '-1px' }}
              >
                <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" />
                  <line x1="19" y1="8" x2="19" y2="14" /><line x1="22" y1="11" x2="16" y2="11" />
                </svg>
                Kayıt Ol
              </Link>
            </div>

            {/* ── FORM ── */}
            <form onSubmit={handleSubmit} noValidate className="space-y-4" aria-describedby={error ? 'form-error' : undefined}>

              {/* Kayıt — Ad + Soyad yan yana */}
              {mode === 'kayit' && (
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label htmlFor="giris-ad" className="mb-1.5 block text-sm font-bold text-textStrong">Ad <span className="text-danger" aria-hidden="true">*</span></label>
                    <div className="relative">
                      <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted">
                        <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
                        </svg>
                      </span>
                      <input
                        id="giris-ad"
                        type="text" value={firstName}
                        onChange={(e) => { setFirstName(e.target.value); clearFieldError('firstName'); }}
                        onBlur={() => handleFieldBlur('firstName')}
                        required autoComplete="given-name" placeholder="Adınız" maxLength={40}
                        aria-invalid={!!fieldErrors.firstName}
                        aria-describedby={fieldErrors.firstName ? 'giris-ad-error' : undefined}
                        className={`h-12 w-full rounded-2xl border bg-bg pl-10 pr-3 text-sm text-text outline-hidden transition focus:ring-2 ${fieldErrors.firstName ? 'border-danger focus:border-danger focus:ring-danger/10' : 'border-border focus:border-primary focus:ring-primary/10'}`}
                      />
                    </div>
                    {fieldErrors.firstName && (
                      <p id="giris-ad-error" role="alert" className="mt-1.5 text-xs font-bold text-danger">{fieldErrors.firstName}</p>
                    )}
                  </div>
                  <div>
                    <label htmlFor="giris-soyad" className="mb-1.5 block text-sm font-bold text-textStrong">Soyad</label>
                    <input
                      id="giris-soyad"
                      type="text" value={lastName} onChange={(e) => setLastName(e.target.value)}
                      autoComplete="family-name" placeholder="Soyadınız" maxLength={40}
                      className="h-12 w-full rounded-2xl border border-border bg-bg px-4 text-sm text-text outline-hidden transition focus:border-primary focus:ring-2 focus:ring-primary/10"
                    />
                  </div>
                </div>
              )}

              {/* E-posta */}
              <div>
                <label htmlFor="giris-eposta" className="mb-1.5 block text-sm font-bold text-textStrong">
                  {mode === 'giris' ? 'E-posta veya Telefon' : 'E-posta'} <span className="text-danger" aria-hidden="true">*</span>
                </label>
                <div className="relative">
                  <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted">
                    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <rect x="2" y="4" width="20" height="16" rx="2" /><path d="m2 7 10 7 10-7" />
                    </svg>
                  </span>
                  <input
                    id="giris-eposta"
                    type="email" value={email}
                    onChange={(e) => { setEmail(e.target.value); clearFieldError('email'); }}
                    onBlur={() => handleFieldBlur('email')}
                    required autoComplete="email"
                    placeholder={mode === 'giris' ? 'E-posta adresiniz veya telefon numaranız' : 'ornek@mail.com'}
                    aria-invalid={!!fieldErrors.email}
                    aria-describedby={fieldErrors.email ? 'giris-eposta-error' : undefined}
                    className={`h-12 w-full rounded-2xl border bg-bg pl-10 pr-4 text-sm text-text outline-hidden transition focus:ring-2 ${fieldErrors.email ? 'border-danger focus:border-danger focus:ring-danger/10' : 'border-border focus:border-primary focus:ring-primary/10'}`}
                  />
                </div>
                {fieldErrors.email && (
                  <p id="giris-eposta-error" role="alert" className="mt-1.5 text-xs font-bold text-danger">{fieldErrors.email}</p>
                )}
              </div>

              {/* Kayıt — Telefon */}
              {mode === 'kayit' && (
                <div>
                  <label htmlFor="giris-telefon" className="mb-1.5 block text-sm font-bold text-textStrong">
                    Telefon <span className="text-xs font-medium text-muted">(opsiyonel)</span>
                  </label>
                  <div className="relative flex">
                    {/* Ülke kodu seçici */}
                    <div className="relative shrink-0">
                      <button
                        type="button"
                        onClick={() => setShowCodePicker((v) => !v)}
                        className="flex h-12 items-center gap-1 rounded-l-2xl border border-r-0 border-border bg-bg px-3 text-sm font-bold text-textStrong hover:bg-cardAlt"
                      >
                        <span>{COUNTRY_CODES.find((c) => c.code === countryCode)?.flag}</span>
                        <span className="text-xs text-muted">{countryCode}</span>
                        <svg viewBox="0 0 24 24" className="h-3 w-3 fill-none stroke-current stroke-2 text-muted" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                          <polyline points="6 9 12 15 18 9" />
                        </svg>
                      </button>
                      {showCodePicker && (
                        <div className="absolute top-full z-50 mt-1 w-40 overflow-hidden rounded-xl border border-border bg-card shadow-yd2">
                          {COUNTRY_CODES.map((c) => (
                            <button
                              key={c.code} type="button"
                              onClick={() => { setCountryCode(c.code); setShowCodePicker(false); }}
                              className={`flex w-full items-center gap-2 px-3 py-2.5 text-sm transition-colors hover:bg-cardAlt ${countryCode === c.code ? 'font-extrabold text-primary' : 'text-textStrong'}`}
                            >
                              <span>{c.flag}</span>
                              <span>{c.code}</span>
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                    <input
                      id="giris-telefon"
                      type="tel" value={phone}
                      onChange={(e) => {
                        const d = e.target.value.replace(/\D/g, '').slice(0, 10);
                        setPhone(d);
                      }}
                      autoComplete="tel" placeholder="5xx xxx xx xx"
                      className="h-12 flex-1 rounded-r-2xl border border-border bg-bg px-4 text-sm text-text outline-hidden transition focus:border-primary focus:ring-2 focus:ring-primary/10"
                    />
                  </div>
                </div>
              )}

              {/* Şifre */}
              <div>
                <div className="mb-1.5 flex items-center justify-between">
                  <label htmlFor="giris-sifre" className="text-sm font-bold text-textStrong">Şifre <span className="text-danger" aria-hidden="true">*</span></label>
                  {mode === 'giris' && (
                    <Link href="/sifremi-unuttum" className="text-sm font-bold text-primary hover:underline">
                      Şifremi unuttum?
                    </Link>
                  )}
                </div>
                <div className="relative">
                  <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted">
                    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
                    </svg>
                  </span>
                  <input
                    id="giris-sifre"
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => { setPassword(e.target.value); clearFieldError('password'); }}
                    onBlur={() => handleFieldBlur('password')}
                    required autoComplete={mode === 'giris' ? 'current-password' : 'new-password'}
                    placeholder="Şifrenizi girin"
                    aria-invalid={!!fieldErrors.password}
                    aria-describedby={fieldErrors.password ? 'giris-sifre-error' : undefined}
                    className={`h-12 w-full rounded-2xl border bg-bg pl-10 pr-11 text-sm text-text outline-hidden transition focus:ring-2 ${fieldErrors.password ? 'border-danger focus:border-danger focus:ring-danger/10' : 'border-border focus:border-primary focus:ring-primary/10'}`}
                  />
                  <button type="button" aria-label={showPassword ? 'Şifreyi gizle' : 'Şifreyi göster'}
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-textStrong">
                    {showPassword
                      ? <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                      : <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    }
                  </button>
                </div>
                {fieldErrors.password ? (
                  <p id="giris-sifre-error" role="alert" className="mt-1.5 text-xs font-bold text-danger">{fieldErrors.password}</p>
                ) : mode === 'kayit' && (
                  <p className="mt-1.5 text-xs text-muted">Şifreniz en az 8 karakter olmalı ve harf, rakam içermelidir.</p>
                )}
              </div>

              {/* Kayıt — Şifre tekrar */}
              {mode === 'kayit' && (
                <div>
                  <label htmlFor="giris-sifre-tekrar" className="mb-1.5 block text-sm font-bold text-textStrong">Şifre (Tekrar) <span className="text-danger" aria-hidden="true">*</span></label>
                  <div className="relative">
                    <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted">
                      <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
                      </svg>
                    </span>
                    <input
                      id="giris-sifre-tekrar"
                      type="password" value={confirmPassword}
                      onChange={(e) => { setConfirmPassword(e.target.value); clearFieldError('confirmPassword'); }}
                      onBlur={() => handleFieldBlur('confirmPassword')}
                      required autoComplete="new-password" placeholder="••••••••"
                      aria-invalid={!!fieldErrors.confirmPassword}
                      aria-describedby={fieldErrors.confirmPassword ? 'giris-sifre-tekrar-error' : undefined}
                      className={`h-12 w-full rounded-2xl border bg-bg pl-10 pr-4 text-sm text-text outline-hidden transition focus:ring-2 ${fieldErrors.confirmPassword ? 'border-danger focus:border-danger focus:ring-danger/10' : 'border-border focus:border-primary focus:ring-primary/10'}`}
                    />
                  </div>
                  {fieldErrors.confirmPassword && (
                    <p id="giris-sifre-tekrar-error" role="alert" className="mt-1.5 text-xs font-bold text-danger">{fieldErrors.confirmPassword}</p>
                  )}
                </div>
              )}

              {/* Kayıt — Doğum tarihi */}
              {mode === 'kayit' && (
                <div>
                  <label htmlFor="giris-dogum-tarihi" className="mb-1.5 block text-sm font-bold text-textStrong">
                    Doğum Tarihi <span className="text-xs font-medium text-muted">(opsiyonel)</span>
                  </label>
                  <div className="relative">
                    <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted">
                      <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" />
                      </svg>
                    </span>
                    <input
                      id="giris-dogum-tarihi"
                      type="date" value={birthDate} onChange={(e) => setBirthDate(e.target.value)}
                      max={new Date(new Date().setFullYear(new Date().getFullYear() - 13)).toISOString().split('T')[0]}
                      min="1920-01-01"
                      className="h-12 w-full rounded-2xl border border-border bg-bg pl-10 pr-4 text-sm text-text outline-hidden transition focus:border-primary focus:ring-2 focus:ring-primary/10"
                    />
                  </div>
                </div>
              )}

              {/* Giriş — Beni hatırla */}
              {mode === 'giris' && (
                <div className="flex items-center justify-between">
                  <label className="flex cursor-pointer items-center gap-2 text-sm text-textStrong">
                    <input type="checkbox" checked={rememberMe} onChange={(e) => setRememberMe(e.target.checked)}
                      className="h-4 w-4 cursor-pointer rounded accent-primary" />
                    Beni hatırla
                  </label>
                </div>
              )}

              {/* Kayıt — Sözleşme */}
              {mode === 'kayit' && (
                <label className="flex cursor-pointer items-start gap-3 rounded-2xl border border-border bg-cardAlt px-4 py-3.5">
                  <input type="checkbox" checked={acceptedTerms} onChange={(e) => setAcceptedTerms(e.target.checked)}
                    className="mt-0.5 h-4 w-4 shrink-0 cursor-pointer accent-primary" required />
                  <span className="text-sm leading-relaxed text-textStrong">
                    <button type="button" onClick={(e) => { e.preventDefault(); e.stopPropagation(); setYasalModal('terms'); }} className="font-extrabold text-primary underline-offset-2 hover:underline">Kullanım Şartları</button>
                    {' '}ve{' '}
                    <button type="button" onClick={(e) => { e.preventDefault(); e.stopPropagation(); setYasalModal('privacy'); }} className="font-extrabold text-primary underline-offset-2 hover:underline">Gizlilik Politikası</button>
                    &apos;nı okudum, kabul ediyorum. <span className="text-danger">*</span>
                  </span>
                </label>
              )}

              {error && (
                <div id="form-error" role="alert" aria-live="polite"
                  className="rounded-2xl border border-danger/25 bg-danger/8 px-4 py-3 text-sm font-bold text-danger">
                  {error}
                </div>
              )}
              {success && (
                <div id="form-success" role="status" aria-live="polite"
                  className="rounded-2xl border border-success/25 bg-success/10 px-4 py-3 text-sm font-bold text-success">
                  {success}
                </div>
              )}

              <button
                type="submit"
                disabled={isPending || (mode === 'kayit' && !acceptedTerms)}
                className="flex h-12 w-full items-center justify-center rounded-2xl bg-primary text-sm font-black text-white shadow-xs transition-all hover:opacity-90 disabled:opacity-60"
              >
                {isPending
                  ? (mode === 'giris' ? 'Giriş yapılıyor…' : 'Hesap oluşturuluyor…')
                  : (mode === 'giris' ? 'Giriş Yap' : 'Kayıt Ol')}
              </button>
            </form>

            {/* Ayraç */}
            <div className="my-5 flex items-center gap-3">
              <div className="h-px flex-1 bg-border" />
              <span className="text-xs font-semibold text-muted">veya</span>
              <div className="h-px flex-1 bg-border" />
            </div>

            {/* Sosyal butonlar */}
            <div className="space-y-3">
              <button type="button" onClick={() => void handleOAuth('google')}
                disabled={isPending || oAuthProvider !== null}
                className="flex h-12 w-full items-center justify-center gap-3 rounded-2xl border border-border bg-card text-sm font-bold text-textStrong shadow-xs transition-colors hover:bg-cardAlt disabled:opacity-50">
                {oAuthProvider === 'google'
                  ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-border border-t-primary" />
                  : <GoogleIcon />}
                Google ile {mode === 'giris' ? 'devam et' : 'kaydol'}
              </button>
              <button type="button" onClick={() => void handleOAuth('apple')}
                disabled={isPending || oAuthProvider !== null}
                className="flex h-12 w-full items-center justify-center gap-3 rounded-2xl border border-border bg-card text-sm font-bold text-textStrong shadow-xs transition-colors hover:bg-cardAlt disabled:opacity-50">
                {oAuthProvider === 'apple'
                  ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-border border-t-textStrong" />
                  : <AppleIcon />}
                Apple ile {mode === 'giris' ? 'devam et' : 'kaydol'}
              </button>
            </div>

            {/* Güvenli giriş rozeti */}
            <div className="mt-5 flex items-center gap-3 rounded-2xl border border-border bg-cardAlt px-4 py-3">
              <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary">
                <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /><polyline points="9 12 11 14 15 10" />
                </svg>
              </span>
              <div>
                <p className="text-sm font-extrabold text-primary">Güvenli {mode === 'giris' ? 'Giriş' : 'Kayıt'}</p>
                <p className="text-xs text-muted">Bilgilerin 256-bit SSL şifreleme ile korunur.</p>
              </div>
            </div>

            {/* Mod değiştirme */}
            <p className="mt-5 text-center text-sm text-muted">
              {mode === 'giris' ? (
                <>Hesabın yok mu?{' '}
                  <Link href="/giris?tab=kayit" className="font-extrabold text-primary hover:underline">Kayıt ol</Link>
                </>
              ) : (
                <>Zaten hesabın var mı?{' '}
                  <Link href="/giris" className="font-extrabold text-primary hover:underline">Giriş yap</Link>
                </>
              )}
            </p>

            {/* Panel linki */}
            {panelLoginUrl && mode === 'giris' && (
              <div className="mt-4 rounded-2xl border border-border bg-cardAlt p-4 text-center">
                <p className="text-xs text-muted">İşletme paneli için ayrı giriş</p>
                <Link href={panelLoginUrl} className="mt-0.5 inline-block text-sm font-extrabold text-primary hover:underline">
                  Panel girişine git →
                </Link>
              </div>
            )}
          </div>
        </div>

        {/* Sağ — Telefon görseli (sadece desktop) */}
        <div
          className="relative hidden flex-1 items-center justify-center overflow-hidden lg:flex"
          style={{ background: 'linear-gradient(135deg, #fff5f5 0%, #fef2f2 50%, #fff8f0 100%)' }}
        >
          <div className="pointer-events-none absolute right-[-80px] top-[-80px] h-[400px] w-[400px] rounded-full bg-primary/5" />
          <div className="pointer-events-none absolute bottom-[-60px] left-[-60px] h-[300px] w-[300px] rounded-full bg-primary/4" />
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/giris-gorsel.webp"
            alt="Yeedoy mobil uygulama"
            className="relative z-10 w-[380px] max-w-[80%] drop-shadow-2xl xl:w-[440px]"
            draggable={false}
          />
        </div>
      </div>

      {/* Yasal Modal */}
      {yasalModal !== null && (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center p-4 sm:items-center"
          role="dialog"
          aria-modal="true"
          aria-labelledby="yasal-modal-baslik"
        >
          <div
            className="absolute inset-0 bg-black/50 backdrop-blur-xs"
            onClick={() => setYasalModal(null)}
            aria-hidden="true"
          />
          <div className="relative z-10 flex max-h-[85vh] w-full max-w-xl flex-col overflow-hidden rounded-3xl bg-card shadow-yd3">
            {/* Başlık */}
            <div className="flex shrink-0 items-center justify-between border-b border-border px-6 py-4">
              <h2 id="yasal-modal-baslik" className="text-base font-black text-textStrong">
                {yasalModal === 'terms' ? 'Kullanım Şartları' : 'Gizlilik Politikası'}
              </h2>
              <button
                type="button"
                onClick={() => setYasalModal(null)}
                aria-label="Kapat"
                className="flex h-8 w-8 items-center justify-center rounded-full text-muted transition-colors hover:bg-cardAlt hover:text-textStrong"
              >
                <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
                </svg>
              </button>
            </div>
            {/* İçerik */}
            <div className="flex-1 overflow-y-auto px-6 py-5 text-sm leading-7 text-text">
              {yasalModal === 'terms' ? (
                <div className="space-y-5">
                  <p className="text-xs font-semibold text-muted">Son güncelleme: Haziran 2026</p>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">1. Hizmet Kapsamı</h3>
                    <p>Yeedoy, kullanıcıların yakınlarındaki yeme-içme mekânlarını keşfetmelerine, değerlendirme yapmalarına ve birbirleriyle paylaşmalarına olanak tanıyan bir platform hizmetidir. Platforma erişim ve kullanım bu şartlara tabidir.</p>
                  </section>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">2. Hesap Yükümlülükleri</h3>
                    <p>Kayıt sırasında verilen bilgilerin doğru ve güncel olması kullanıcının sorumluluğundadır. Hesap güvenliğini sağlamak, şifreyi üçüncü şahıslarla paylaşmamak zorunludur. Şüpheli bir aktivite fark ettiğinizde destek@yeedoy.com adresini bilgilendirmeniz gerekmektedir.</p>
                  </section>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">3. İçerik Politikası</h3>
                    <p>Platforma yüklenen içerikler (yorum, fotoğraf, öneri) gerçek deneyimlere dayanmalı; yanıltıcı, hakaret içeren veya başkasının haklarını ihlal eden içerik barındırmamalıdır. Yeedoy, politikaya aykırı içerikleri kaldırma hakkını saklı tutar.</p>
                  </section>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">4. Fikri Mülkiyet</h3>
                    <p>Platforma yüklenen içeriklerin telif hakkı kullanıcıya aittir; ancak kullanıcı, Yeedoy&apos;a bu içerikleri platform dahilinde ücretsiz kullanma lisansı vermektedir. Yeedoy&apos;un marka ve logoları izinsiz kullanılamaz.</p>
                  </section>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">5. Sorumluluk Sınırları</h3>
                    <p>Yeedoy, mekânların sunduğu hizmetlerin kalitesi veya sürekliliği konusunda garanti vermez. Kullanıcı yorumları üçüncü şahıslara aittir; Yeedoy doğruluklarından sorumlu tutulamaz.</p>
                  </section>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">6. Değişiklikler</h3>
                    <p>Bu şartlar önceden bildirim yapılarak değiştirilebilir. Değişiklik sonrasında platforma erişmeye devam etmek, güncel şartları kabul ettiğiniz anlamına gelir.</p>
                  </section>
                </div>
              ) : (
                <div className="space-y-5">
                  <p className="text-xs font-semibold text-muted">Son güncelleme: Haziran 2026</p>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">1. Topladığımız Veriler</h3>
                    <p>Kayıt sırasında ad, soyad, e-posta ve isteğe bağlı telefon/doğum tarihi bilgilerinizi toplarız. Platform kullanımı sırasında tercihler, yorumlar, konum bilgisi (izin verildiyse) ve cihaz verileri işlenir.</p>
                  </section>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">2. Verilerin Kullanımı</h3>
                    <p>Toplanan veriler; kişiselleştirilmiş öneri sunma, hesap güvenliği, müşteri desteği ve hizmet iyileştirme amaçlarıyla kullanılır. Verileriniz üçüncü taraflarla izniniz olmadan paylaşılmaz; yalnızca yasal zorunluluk halinde yetkili mercilere açıklanabilir.</p>
                  </section>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">3. Çerezler</h3>
                    <p>Oturum yönetimi ve analitik amaçlarla çerez kullanılır. Tarayıcı ayarlarınızdan çerezleri devre dışı bırakabilirsiniz; ancak bu durum bazı özelliklerin çalışmamasına yol açabilir.</p>
                  </section>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">4. Veri Güvenliği</h3>
                    <p>Verileriniz 256-bit SSL şifreleme ile iletilir ve güvenli altyapıda saklanır. Yetkisiz erişim, kayıp veya imha riskine karşı endüstri standardı teknik tedbirler uygulanmaktadır.</p>
                  </section>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">5. Haklarınız</h3>
                    <p>KVKK kapsamında verilerinize erişme, düzeltme, silme ve taşınabilirlik haklarına sahipsiniz. Bu hakları kullanmak için destek@yeedoy.com adresine başvurabilirsiniz.</p>
                  </section>
                  <section>
                    <h3 className="mb-2 text-sm font-black text-textStrong">6. İletişim</h3>
                    <p>Gizlilik politikamız hakkında sorularınız için <span className="font-bold text-textStrong">destek@yeedoy.com</span> adresinden bize ulaşabilirsiniz.</p>
                  </section>
                </div>
              )}
            </div>
            {/* Alt buton */}
            <div className="shrink-0 border-t border-border px-6 py-4">
              <button
                type="button"
                onClick={() => setYasalModal(null)}
                className="flex h-11 w-full items-center justify-center rounded-2xl bg-primary text-sm font-black text-white shadow-xs transition-all hover:opacity-90"
              >
                Anladım, Kapat
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Alt — 4 özellik satırı */}
      <div className="border-t border-border bg-bg px-6 py-8">
        <div className="mx-auto grid max-w-4xl grid-cols-2 gap-6 sm:grid-cols-4">
          {[
            {
              icon: <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>,
              title: 'Yakınındaki lezzetler',
              desc: 'Konumuna en uygun mekanları keşfet',
            },
            {
              icon: <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M20 12V22H4V12"/><path d="M22 7H2v5h20V7z"/><path d="M12 22V7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/></svg>,
              title: 'Özel kampanyalar',
              desc: 'Sana özel fırsatları kaçırma',
            },
            {
              icon: <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>,
              title: 'Favorilerini kaydet',
              desc: 'Beğendiğin mekanları kolayca bul',
            },
            {
              icon: <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>,
              title: 'Doğru yorumlar',
              desc: 'Gerçek kullanıcı yorumlarıyla doğru tercih yap',
            },
          ].map((item) => (
            <div key={item.title} className="flex items-start gap-3">
              <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary">
                {item.icon}
              </span>
              <div>
                <p className="text-sm font-extrabold text-textStrong">{item.title}</p>
                <p className="mt-0.5 text-xs leading-relaxed text-muted">{item.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
