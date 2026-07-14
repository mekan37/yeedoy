import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { YeedoyLogo } from '@/src/ui/brand/yeedoy-logo';
import { ForbiddenActions } from './forbidden-actions';

export const metadata: Metadata = {
  title: 'Erişim Yok | Yeedoy',
  robots: { index: false, follow: false },
};

export default async function ForbiddenPage() {
  let user = null;
  let displayName: string | null = null;
  let avatarUrl: string | null = null;

  try {
    const supabase = await createSupabaseServerClient();
    const { data: { user: sessionUser }, error } = await supabase.auth.getUser();
    if (!error && sessionUser) {
      user = sessionUser;
      const { data: profile } = await (supabase as any)
        .from('user_profiles')
        .select('display_name, avatar_url')
        .eq('user_id', sessionUser.id)
        .maybeSingle();
      displayName = (profile?.display_name as string | null) ?? sessionUser.email?.split('@')[0] ?? null;
      avatarUrl = (profile?.avatar_url as string | null) ?? null;
    }
  } catch {
    // Session error (e.g. expired refresh token) — show page without user info
  }

  return (
    <div className="flex min-h-screen flex-col bg-[#f6f7f9]">
      {/* ── Header ── */}
      <header className="border-b border-[#f0f0f0] bg-white px-8 py-4">
        <div className="mx-auto flex max-w-6xl items-center justify-between">
          <div className="flex items-center gap-3">
            <Link href="/">
              <YeedoyLogo size={32} />
            </Link>
            <Link
              href="/sahip/gosterge-panosu"
              className="flex items-center gap-1.5 rounded-full border border-[#e5e7eb] px-3 py-1 text-xs font-[700] text-[#374151] transition hover:border-[#dc2626]/30 hover:text-[#dc2626]"
            >
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
                <polyline points="15 3 21 3 21 9" />
                <line x1="10" y1="14" x2="21" y2="3" />
              </svg>
              İşletme Paneli
            </Link>
          </div>

          {user && (
            <div className="flex items-center gap-2.5">
              {avatarUrl ? (
                <Image src={avatarUrl} alt="" width={36} height={36} className="h-9 w-9 rounded-full object-cover ring-2 ring-[#f0f0f0]" />
              ) : (
                <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[#7f1d1d] text-sm font-[900] text-white">
                  {(displayName ?? 'K')[0].toUpperCase()}
                </div>
              )}
              <div>
                <p className="text-sm font-[800] text-[#111827]">{displayName ?? 'Kullanıcı'}</p>
                <p className="text-xs text-[#6b7280]">İşletme Sahibi</p>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="6 9 12 15 18 9" />
              </svg>
            </div>
          )}
        </div>
      </header>

      {/* ── Main ── */}
      <main className="flex flex-1 items-start justify-center px-4 py-12">
        <div className="w-full max-w-5xl overflow-hidden rounded-3xl border border-[#ebebeb] bg-white shadow-[0_4px_40px_rgba(0,0,0,0.07)]">
          <div className="grid grid-cols-1 lg:grid-cols-[1fr_340px]">
            {/* ── Left column ── */}
            <div className="flex flex-col items-center px-10 py-14 text-center lg:border-r lg:border-[#f3f4f6]">
              {/* Shield illustration */}
              <div className="relative mb-8 flex items-center justify-center">
                {/* Outer pink glow */}
                <div className="absolute h-48 w-48 rounded-full bg-[#fef2f2] opacity-70" />
                {/* Inner pink ring */}
                <div className="absolute h-36 w-36 rounded-full border-4 border-dashed border-[#fecaca] bg-transparent" style={{ opacity: 0.5 }} />
                {/* Shield SVG */}
                <div className="relative z-10">
                  <svg width="120" height="130" viewBox="0 0 120 130" fill="none">
                    <defs>
                      <linearGradient id="shieldGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#ef4444" />
                        <stop offset="100%" stopColor="#991b1b" />
                      </linearGradient>
                      <linearGradient id="shieldHighlight" x1="0" y1="0" x2="1" y2="0">
                        <stop offset="0%" stopColor="#ffffff" stopOpacity="0.15" />
                        <stop offset="100%" stopColor="#ffffff" stopOpacity="0" />
                      </linearGradient>
                      <filter id="shieldShadow" x="-20%" y="-10%" width="140%" height="140%">
                        <feDropShadow dx="0" dy="8" stdDeviation="12" floodColor="#dc2626" floodOpacity="0.35" />
                      </filter>
                    </defs>
                    {/* Main shield */}
                    <path
                      d="M60 4 L108 24 L108 68 C108 96 88 118 60 126 C32 118 12 96 12 68 L12 24 Z"
                      fill="url(#shieldGrad)"
                      filter="url(#shieldShadow)"
                    />
                    {/* Highlight overlay */}
                    <path
                      d="M60 4 L108 24 L108 68 C108 96 88 118 60 126 C32 118 12 96 12 68 L12 24 Z"
                      fill="url(#shieldHighlight)"
                    />
                    {/* Lock body */}
                    <rect x="42" y="62" width="36" height="28" rx="5" fill="white" opacity="0.95" />
                    {/* Lock shackle */}
                    <path d="M48 62 L48 54 C48 46 72 46 72 54 L72 62" stroke="white" strokeWidth="6" strokeLinecap="round" fill="none" opacity="0.95" />
                    {/* Keyhole */}
                    <circle cx="60" cy="75" r="4.5" fill="#dc2626" />
                    <rect x="57.5" y="75" width="5" height="7" rx="1" fill="#dc2626" />
                  </svg>
                </div>
                {/* X badge */}
                <div className="absolute right-4 top-4 z-20 flex h-9 w-9 items-center justify-center rounded-full bg-white shadow-[0_2px_12px_rgba(0,0,0,0.15)]">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#ef4444" strokeWidth="3" strokeLinecap="round">
                    <line x1="18" y1="6" x2="6" y2="18" />
                    <line x1="6" y1="6" x2="18" y2="18" />
                  </svg>
                </div>
              </div>

              {/* "Yetki gerekli" badge */}
              <div className="mb-5 inline-flex items-center gap-2 rounded-full bg-[#fef2f2] px-4 py-1.5">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
                <span className="text-sm font-[800] text-[#dc2626]">Yetki gerekli</span>
              </div>

              {/* Title */}
              <h1 className="text-[30px] font-[900] leading-tight text-[#111827]">
                Bu sayfaya erişiminiz yok
              </h1>
              <p className="mt-3 max-w-sm text-sm leading-relaxed text-[#6b7280]">
                Bu alanı görüntülemek için gerekli yetkiye sahip değilsiniz.
                İşletme sahibi veya yönetici hesabıyla giriş yapmanız gerekebilir.
              </p>

              {/* Buttons */}
              <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
                <ForbiddenActions />
              </div>

              {/* Switch account link */}
              <Link
                href="/giris"
                className="mt-4 flex items-center gap-2 text-sm font-[700] text-[#dc2626] hover:underline"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                  <circle cx="12" cy="7" r="4" />
                </svg>
                Farklı hesapla giriş yap
              </Link>

              {/* Info box */}
              <div className="mt-8 flex w-full max-w-md items-start gap-3 rounded-2xl border border-[#d1fae5] bg-[#f0fdf4] px-5 py-4 text-left">
                <div className="mt-0.5 flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full border-2 border-[#86efac]">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="10" />
                    <line x1="12" y1="8" x2="12" y2="12" />
                    <line x1="12" y1="16" x2="12.01" y2="16" />
                  </svg>
                </div>
                <div>
                  <p className="text-sm text-[#374151]">
                    <span className="font-[800] text-[#15803d]">Erişim talebi oluşturabilir</span>{' '}
                    veya işletme yöneticinle iletişime geçebilirsin.
                  </p>
                  <p className="mt-1 text-xs text-[#6b7280]">
                    Gerekli yetkiler tanımlandığında bu sayfaya erişim sağlayabileceksin.
                  </p>
                </div>
              </div>
            </div>

            {/* ── Right column ── */}
            <div className="px-8 py-14">
              <h2 className="mb-6 text-base font-[900] text-[#111827]">Yaygın nedenler</h2>

              <div className="flex flex-col gap-5">
                {[
                  {
                    icon: (
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                        <circle cx="12" cy="7" r="4" />
                      </svg>
                    ),
                    title: 'Yanlış hesapla giriş yaptınız',
                    desc: 'Bu sayfa, başka bir hesapta bulunuyor olabilir.',
                  },
                  {
                    icon: (
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                        <line x1="12" y1="8" x2="12" y2="12" />
                        <line x1="12" y1="16" x2="12.01" y2="16" />
                      </svg>
                    ),
                    title: 'Yetki eksikliği',
                    desc: 'Bu alanı görüntülemek için gerekli role sahip olmayabilirsiniz.',
                  },
                  {
                    icon: (
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <circle cx="12" cy="12" r="10" />
                        <polyline points="12 6 12 12 16 14" />
                      </svg>
                    ),
                    title: 'Onay bekleyen işletme',
                    desc: 'İşletmenizin onay süreci devam ediyor olabilir.',
                  },
                ].map((item) => (
                  <div key={item.title} className="flex items-start gap-4">
                    <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-[#fef2f2]">
                      {item.icon}
                    </div>
                    <div>
                      <p className="text-sm font-[800] text-[#111827]">{item.title}</p>
                      <p className="mt-0.5 text-xs leading-relaxed text-[#6b7280]">{item.desc}</p>
                    </div>
                  </div>
                ))}
              </div>

              {/* Divider */}
              <div className="my-6 border-t border-[#f3f4f6]" />

              {/* Support box */}
              <div className="rounded-2xl border border-[#f3f4f6] bg-[#fafafa] p-5">
                <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-full bg-[#f3f4f6]">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#374151" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M3 18v-6a9 9 0 0 1 18 0v6" />
                    <path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z" />
                  </svg>
                </div>
                <p className="text-sm font-[800] text-[#111827]">Yardıma mı ihtiyacınız var?</p>
                <p className="mt-1 text-xs leading-relaxed text-[#6b7280]">
                  Destek ekibimiz size en kısa sürede yardımcı olacaktır.
                </p>
                <a href="#" className="mt-3 inline-flex items-center gap-1 text-sm font-[800] text-[#dc2626] hover:underline">
                  Destek Merkezi&apos;ni Ziyaret Et
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <line x1="5" y1="12" x2="19" y2="12" />
                    <polyline points="12 5 19 12 12 19" />
                  </svg>
                </a>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* ── Footer ── */}
      <footer className="px-8 py-5">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 text-xs text-[#9ca3af]">
          <span>© 2024 Yeedoy. Tüm hakları saklıdır.</span>
          <div className="flex gap-5">
            <Link href="/legal" className="hover:text-[#374151] transition">Kullanım Koşulları</Link>
            <Link href="/legal" className="hover:text-[#374151] transition">Gizlilik Politikası</Link>
            <a href="#" className="hover:text-[#374151] transition">Yardım Merkezi</a>
          </div>
        </div>
      </footer>
    </div>
  );
}
