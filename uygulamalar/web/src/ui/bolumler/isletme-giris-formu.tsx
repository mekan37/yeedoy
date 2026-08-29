'use client';

import { useEffect, useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';
import { GoogleIcon } from './giris-ikon';
import { hataMesaji } from './giris-yardimci';
import { IsletmePanelOnizleme } from './isletme-panel-onizleme';

type Mode = 'giris' | 'kayit';

const KATEGORILER = [
  'Restoran', 'Kafe', 'Pastane', 'Fast Food', 'Dönerci', 'Pide / Lahmacun',
  'Pizza', 'Burger', 'Balık', 'Çorba', 'Tatlıcı', 'Kahvaltı', 'Diğer',
];

const GIRIS_OZELLIKLER = [
  { icon: <MenuIconSvg />, title: 'Menünü yönet', desc: 'Ürünlerini düzenle, fiyatları güncelle, görselleri yönet.' },
  { icon: <ChatIconSvg />, title: 'Yorumları takip et', desc: 'Müşteri yorumlarını oku, yanıtla ve memnuniyeti artır.' },
  { icon: <ChartIconSvg />, title: 'İstatistikleri gör', desc: 'Performansını analiz et, doğru kararlar al.' },
];

const KAYIT_OZELLIKLER = [
  { icon: <MenuIconSvg />, title: 'Menünü yönet', desc: 'Menü, fiyat ve içerikleri kolayca güncelle.' },
  { icon: <ChatIconSvg />, title: 'Yorumları takip et', desc: 'Müşteri yorumlarını oku, yanıtla ve memnuniyeti artır.' },
  { icon: <ChartIconSvg />, title: 'İstatistiklerle büyü', desc: 'Detaylı raporlarla performansını analiz et, doğru kararlar al.' },
];

type Props = {
  initialTab?: Mode;
};

export function IsletmeGirisFormu({ initialTab = 'giris' }: Props) {
  const router = useRouter();
  const mode: Mode = initialTab;

  // Giriş
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(false);

  // Kayıt
  const [businessName, setBusinessName] = useState('');
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [category, setCategory] = useState('');
  const [city, setCity] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [acceptedTerms, setAcceptedTerms] = useState(false);

  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isPending, startTransition] = useTransition();
  const [googlePending, setGooglePending] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    try {
      const saved = localStorage.getItem('yd_isletme_beni_hatirla');
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
      router.replace('/sahip/gosterge-panosu');
      router.refresh();
    }
    void syncExistingSession();
    return () => { ignore = true; };
  }, [router]);

  async function handleGoogle() {
    setGooglePending(true);
    const supabase = createSupabaseBrowserClient();
    const callbackUrl = new URL('/auth/callback', window.location.origin);
    callbackUrl.searchParams.set('redirect', '/sahip/gosterge-panosu');
    await supabase.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: callbackUrl.toString() } });
    setGooglePending(false);
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (mode === 'kayit') {
      if (!businessName.trim()) { setError('İşletme adı zorunludur.'); return; }
      if (!fullName.trim()) { setError('Yetkili ad soyad zorunludur.'); return; }
      if (!category) { setError('İşletme kategorisi seçmelisiniz.'); return; }
      if (!city.trim()) { setError('Şehir zorunludur.'); return; }
      if (password !== confirmPassword) { setError('Şifreler eşleşmiyor.'); return; }
      if (password.length < 8) { setError('Şifre en az 8 karakter olmalıdır.'); return; }
      if (!acceptedTerms) { setError('Devam etmek için Kullanım Şartları ve Gizlilik Politikası\'nı kabul etmelisiniz.'); return; }
    }

    startTransition(async () => {
      if (mode === 'giris') {
        const response = await fetch('/sunucu/kimlik/giris', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: email.trim(), password, redirectTo: '/sahip/gosterge-panosu' }),
        });
        const result = await response.json().catch(() => null) as { redirectTo?: string; error?: string } | null;
        if (!response.ok) {
          setError(hataMesaji(result?.error ?? 'auth_failed'));
          return;
        }
        try {
          if (rememberMe) localStorage.setItem('yd_isletme_beni_hatirla', email.trim());
          else localStorage.removeItem('yd_isletme_beni_hatirla');
        } catch { /* ignore */ }
        window.location.assign(result?.redirectTo ?? '/sahip/gosterge-panosu');
        router.refresh();
        return;
      }

      // ── Kayıt: hesap oluştur + işletme başvurusunu tek adımda gönder ──
      const supabase = createSupabaseBrowserClient();
      const normalizedPhone = phone.trim() ? `+90${phone.replace(/\D/g, '')}` : null;

      const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          emailRedirectTo: `${window.location.origin}/auth/callback?redirect=${encodeURIComponent('/sahip/gosterge-panosu')}`,
          data: {
            display_name: fullName.trim(),
            full_name: fullName.trim(),
            ...(normalizedPhone && { phone: normalizedPhone }),
          },
        },
      });
      if (signUpError) { setError(hataMesaji(signUpError)); return; }

      if (!signUpData.session) {
        setSuccess('Hesabın oluşturuldu! Doğrulama e-postası gönderildi — e-postanı onayladıktan sonra giriş yapıp işletme başvurunu tamamlayabilirsin.');
        return;
      }

      const userId = signUpData.session.user.id;
      const { error: profileError } = await (supabase as any).from('user_profiles').insert({
        user_id: userId,
        display_name: fullName.trim(),
        ...(normalizedPhone && { phone: normalizedPhone }),
      }) as { error: { code?: string } | null };
      if (profileError && profileError.code !== '23505') {
        setError('Hesap oluşturuldu ancak profil kaydedilemedi. Giriş yapıp tekrar deneyebilirsin.');
        return;
      }

      const { data: rpcData } = await (supabase as any).rpc('owner_submit_new_business_v1', {
        p_name: businessName.trim(),
        p_city: city.trim(),
        p_district: city.trim(),
        p_category: category,
        p_address: '',
        p_phone: normalizedPhone,
        p_website: null,
      }) as { data: { ok: boolean } | null };

      window.location.assign(rpcData?.ok ? '/sahip/gosterge-panosu?bilgi=talep_alindi' : '/sahip/gosterge-panosu');
      router.refresh();
    });
  }

  return (
    <div className="flex min-h-screen flex-col">
      {/* Minimal üst çubuk */}
      <header className="flex h-16 shrink-0 items-center justify-between border-b border-border px-6">
        <Link href="/" aria-label="Yeedoy anasayfa">
          <YeedoyLogo size={26} />
        </Link>
        <Link
          href="/sahip"
          className="flex items-center gap-1.5 rounded-xl border border-border px-3.5 py-2 text-xs font-extrabold text-textStrong transition-colors hover:border-primary hover:text-primary"
        >
          İşletme Paneli
          <ExternalLinkIconSvg />
        </Link>
      </header>

      <div className="flex flex-1 flex-col lg:flex-row">
      {/* Sol — Form paneli */}
      <div className="flex w-full items-start justify-center px-6 py-10 lg:w-[480px] lg:shrink-0 lg:px-12 lg:py-14 xl:w-[520px]">
        <div className="w-full max-w-[420px]">
          <div className="mb-6 flex h-11 w-11 items-center justify-center rounded-2xl bg-primary/10 text-primary">
            {mode === 'giris' ? <LockIconSvg /> : <StoreIconSvg />}
          </div>

          <div className="mb-7">
            <h1 className="text-[1.75rem] font-black leading-tight text-textStrong">
              İşletme Paneline {mode === 'giris' ? 'Giriş Yap' : 'Kayıt Ol'}
            </h1>
            <p className="mt-2 text-sm leading-relaxed text-muted">
              {mode === 'giris'
                ? 'İşletmenizi yönetmek için hesabınıza giriş yapın.'
                : 'İşletmeni yönetmek için hesabını oluştur.'}
            </p>
          </div>

          {/* Sekmeler */}
          <div className="mb-7 flex border-b border-border">
            <Link
              href="/isletme-giris"
              className={`flex items-center px-1 pb-3 text-sm font-extrabold transition-colors ${
                mode === 'giris' ? 'border-b-2 border-primary text-primary' : 'text-muted hover:text-textStrong'
              }`}
              style={{ marginBottom: '-1px' }}
            >
              Giriş Yap
            </Link>
            <Link
              href="/isletme-kayit"
              className={`ml-6 flex items-center px-1 pb-3 text-sm font-extrabold transition-colors ${
                mode === 'kayit' ? 'border-b-2 border-primary text-primary' : 'text-muted hover:text-textStrong'
              }`}
              style={{ marginBottom: '-1px' }}
            >
              Kayıt Ol
            </Link>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4" aria-describedby={error ? 'form-error' : undefined}>
            {mode === 'kayit' && (
              <>
                <Alan label="İşletme Adı" htmlFor="panel-isletme-adi" required>
                  <input
                    id="panel-isletme-adi"
                    type="text" value={businessName} onChange={(e) => setBusinessName(e.target.value)}
                    required placeholder="İşletme adınızı girin" maxLength={120}
                    className={INPUT_CLS}
                  />
                </Alan>
                <Alan label="Yetkili Ad Soyad" htmlFor="panel-yetkili-ad" required>
                  <input
                    id="panel-yetkili-ad"
                    type="text" value={fullName} onChange={(e) => setFullName(e.target.value)}
                    required autoComplete="name" placeholder="Adınız ve soyadınız" maxLength={80}
                    className={INPUT_CLS}
                  />
                </Alan>
              </>
            )}

            <div className={mode === 'kayit' ? 'grid grid-cols-2 gap-3' : ''}>
              <Alan label={mode === 'giris' ? 'E-posta veya Telefon' : 'E-posta'} htmlFor="panel-eposta" required>
                <input
                  id="panel-eposta"
                  type="email" value={email} onChange={(e) => setEmail(e.target.value)}
                  required autoComplete="email"
                  placeholder={mode === 'giris' ? 'E-posta adresiniz' : 'ornek@isletme.com'}
                  className={INPUT_CLS}
                />
              </Alan>
              {mode === 'kayit' && (
                <Alan label="Telefon" htmlFor="panel-telefon">
                  <input
                    id="panel-telefon"
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value.replace(/\D/g, '').slice(0, 10))}
                    autoComplete="tel" placeholder="5XX XXX XX XX"
                    className={INPUT_CLS}
                  />
                </Alan>
              )}
            </div>

            <div className={mode === 'kayit' ? 'grid grid-cols-2 gap-3' : ''}>
              <Alan
                label="Şifre"
                htmlFor="panel-sifre"
                required
                right={mode === 'giris' ? <Link href="/sifremi-unuttum" className="text-sm font-bold text-primary hover:underline">Şifremi unuttum?</Link> : undefined}
              >
                <div className="relative">
                  <input
                    id="panel-sifre"
                    type={showPassword ? 'text' : 'password'}
                    value={password} onChange={(e) => setPassword(e.target.value)}
                    required autoComplete={mode === 'giris' ? 'current-password' : 'new-password'}
                    placeholder={mode === 'giris' ? 'Şifrenizi girin' : 'En az 8 karakter'}
                    className={`${INPUT_CLS} pr-11`}
                  />
                  <button type="button" aria-label={showPassword ? 'Şifreyi gizle' : 'Şifreyi göster'}
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-textStrong">
                    <EyeIconSvg off={showPassword} />
                  </button>
                </div>
              </Alan>
              {mode === 'kayit' && (
                <Alan label="Şifre Tekrar" htmlFor="panel-sifre-tekrar" required>
                  <input
                    id="panel-sifre-tekrar"
                    type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)}
                    required autoComplete="new-password" placeholder="Şifrenizi tekrar girin"
                    className={INPUT_CLS}
                  />
                </Alan>
              )}
            </div>

            {mode === 'kayit' && (
              <div className="grid grid-cols-2 gap-3">
                <Alan label="İşletme Kategorisi" htmlFor="panel-kategori" required>
                  <select id="panel-kategori" value={category} onChange={(e) => setCategory(e.target.value)} required className={INPUT_CLS}>
                    <option value="">Kategori seçin</option>
                    {KATEGORILER.map((k) => <option key={k} value={k}>{k}</option>)}
                  </select>
                </Alan>
                <Alan label="Şehir" htmlFor="panel-sehir" required>
                  <input
                    id="panel-sehir"
                    type="text" value={city} onChange={(e) => setCity(e.target.value)}
                    required placeholder="Şehir seçin" maxLength={80}
                    className={INPUT_CLS}
                  />
                </Alan>
              </div>
            )}

            {mode === 'giris' && (
              <label className="flex cursor-pointer items-center gap-2 text-sm text-textStrong">
                <input type="checkbox" checked={rememberMe} onChange={(e) => setRememberMe(e.target.checked)}
                  className="h-4 w-4 cursor-pointer rounded accent-primary" />
                Beni hatırla
              </label>
            )}

            {mode === 'kayit' && (
              <label className="flex cursor-pointer items-start gap-2.5 text-xs leading-relaxed text-textStrong">
                <input type="checkbox" checked={acceptedTerms} onChange={(e) => setAcceptedTerms(e.target.checked)}
                  className="mt-0.5 h-4 w-4 shrink-0 cursor-pointer accent-primary" required />
                <span>
                  <Link href="/yasal/terms" target="_blank" className="font-extrabold text-primary hover:underline">Kullanım koşullarını</Link>{' '}kabul ediyorum.
                </span>
              </label>
            )}
            {mode === 'kayit' && (
              <label className="flex cursor-pointer items-start gap-2.5 text-xs leading-relaxed text-textStrong">
                <input type="checkbox" required className="mt-0.5 h-4 w-4 shrink-0 cursor-pointer accent-primary" />
                <span>
                  <Link href="/yasal/privacy" target="_blank" className="font-extrabold text-primary hover:underline">Gizlilik politikasını</Link>{' '}okudum.
                </span>
              </label>
            )}

            {error && (
              <div id="form-error" role="alert" aria-live="polite"
                className="rounded-xl border border-danger/25 bg-danger/8 px-4 py-3 text-sm font-bold text-danger">
                {error}
              </div>
            )}
            {success && (
              <div role="status" aria-live="polite"
                className="rounded-xl border border-success/25 bg-success/10 px-4 py-3 text-sm font-bold text-success">
                {success}
              </div>
            )}

            <button
              type="submit"
              disabled={isPending || (mode === 'kayit' && !acceptedTerms)}
              className="flex h-12 w-full items-center justify-center rounded-xl bg-primary text-sm font-black text-white shadow-xs transition-all hover:opacity-90 disabled:opacity-60"
            >
              {isPending
                ? (mode === 'giris' ? 'Giriş yapılıyor…' : 'Kayıt olunuyor…')
                : (mode === 'giris' ? 'Giriş Yap' : 'Kayıt Ol')}
            </button>
          </form>

          <div className="my-5 flex items-center gap-3">
            <div className="h-px flex-1 bg-border" />
            <span className="text-xs font-semibold text-muted">veya</span>
            <div className="h-px flex-1 bg-border" />
          </div>

          <div className="space-y-3">
            <button type="button" onClick={() => void handleGoogle()}
              disabled={isPending || googlePending}
              className="flex h-12 w-full items-center justify-center gap-3 rounded-xl border border-border bg-card text-sm font-bold text-textStrong shadow-xs transition-colors hover:bg-cardAlt disabled:opacity-50">
              {googlePending
                ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-border border-t-primary" />
                : <GoogleIcon />}
              Google ile devam et
            </button>
            <button type="button" disabled title="Yakında"
              className="flex h-12 w-full cursor-not-allowed items-center justify-center gap-3 rounded-xl border border-border bg-card text-sm font-bold text-muted opacity-60">
              <PhoneIconSvg />
              Telefon ile giriş
              <span className="rounded-full bg-muted/15 px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-wide text-muted">Yakında</span>
            </button>
          </div>

          <div className="mt-5 flex items-center gap-3 rounded-xl border border-border bg-cardAlt px-4 py-3">
            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary">
              <ShieldIconSvg />
            </span>
            <div>
              <p className="text-sm font-extrabold text-primary">Güvenli {mode === 'giris' ? 'Giriş' : 'Kayıt'}</p>
              <p className="text-xs text-muted">Bilgilerin 256-bit SSL şifreleme ile korunur.</p>
            </div>
          </div>

          <p className="mt-5 text-center text-sm text-muted">
            {mode === 'giris' ? (
              <>Henüz işletme hesabın yok mu?{' '}
                <Link href="/isletme-kayit" className="font-extrabold text-primary hover:underline">Kayıt ol →</Link>
              </>
            ) : (
              <>Zaten hesabın var mı?{' '}
                <Link href="/isletme-giris" className="font-extrabold text-primary hover:underline">Giriş yap</Link>
              </>
            )}
          </p>

          <div className="mt-4 rounded-xl border border-border bg-cardAlt p-4 text-center">
            <p className="text-xs text-muted">Müşteri hesabı mı arıyorsun?</p>
            <Link href="/giris" className="mt-0.5 inline-block text-sm font-extrabold text-primary hover:underline">
              Müşteri girişine git →
            </Link>
          </div>
        </div>
      </div>

      {/* Sağ — marka/panel önizleme */}
      <IsletmePanelOnizleme
        eyebrow="İşletme Sahipleri İçin"
        titleLine1={mode === 'giris' ? 'Yeedoy İşletme Paneli ile' : 'Yeedoy ile işletmeni'}
        titleLine2={mode === 'giris' ? 'işletmeni büyüt' : 'dijitalde güçlendir'}
        description={
          mode === 'giris'
            ? 'Siparişlerinden yorumlara, istatistiklerden kampanyalara kadar tüm süreçleri tek panelden yönet.'
            : 'Menünü yönet, yorumları takip et, kampanyalar oluştur ve istatistiklerle işletmeni büyüt.'
        }
        features={mode === 'giris' ? GIRIS_OZELLIKLER : KAYIT_OZELLIKLER}
      />
      </div>
    </div>
  );
}

const INPUT_CLS = 'h-12 w-full rounded-xl border border-border bg-bg px-4 text-sm text-text outline-hidden transition focus:border-primary focus:ring-2 focus:ring-primary/10';

function Alan({
  label,
  htmlFor,
  right,
  required,
  children,
}: {
  label: string;
  htmlFor: string;
  right?: React.ReactNode;
  required?: boolean;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div className="mb-1.5 flex items-center justify-between">
        <label htmlFor={htmlFor} className="text-sm font-bold text-textStrong">
          {label}
          {required && <span className="ml-0.5 text-danger" aria-hidden="true">*</span>}
        </label>
        {right}
      </div>
      {children}
    </div>
  );
}

function EyeIconSvg({ off }: { off: boolean }) {
  return off ? (
    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" /><line x1="1" y1="1" x2="23" y2="23" /></svg>
  ) : (
    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>
  );
}

function ExternalLinkIconSvg() {
  return (
    <svg viewBox="0 0 24 24" width="13" height="13" className="fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" /><polyline points="15 3 21 3 21 9" /><line x1="10" y1="14" x2="21" y2="3" />
    </svg>
  );
}

function LockIconSvg() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg>
  );
}

function StoreIconSvg() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M3 9l1-5h16l1 5" /><path d="M3 9a2 2 0 0 0 4 0 2 2 0 0 0 4 0 2 2 0 0 0 4 0 2 2 0 0 0 4 0" /><path d="M4 9v10h16V9" /><path d="M9 21v-6h6v6" /></svg>
  );
}

function ShieldIconSvg() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /><polyline points="9 12 11 14 15 10" /></svg>
  );
}

function PhoneIconSvg() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" /></svg>
  );
}

function MenuIconSvg() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /><line x1="16" y1="13" x2="8" y2="13" /><line x1="16" y1="17" x2="8" y2="17" /></svg>
  );
}

function ChatIconSvg() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" /></svg>
  );
}

function ChartIconSvg() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" /></svg>
  );
}
