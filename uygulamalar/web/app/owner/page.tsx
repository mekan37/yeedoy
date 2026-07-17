import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { redirect } from 'next/navigation';
import { YeedoyLogo } from '@/src/ui/brand/yeedoy-logo';
import { OwnerLandingSearch } from './owner-landing-search';

export const metadata: Metadata = {
  title: 'İşletme Paneli | Yeedoy',
  description: 'Yeedoy İşletme Paneli ile menünüzü yönetin, yorumları takip edin, istatistikleri görün.',
  robots: { index: true, follow: true },
};

export default async function OwnerLandingPage() {
  // Already logged-in owners with an approved claim go straight to dashboard.
  // next/navigation redirect() works by throwing a special NEXT_REDIRECT error,
  // so we resolve the flag first (inside try/catch for auth errors only) and
  // call redirect() outside the catch so it is never swallowed.
  let goToDashboard = false;
  try {
    const supabase = await createSupabaseServerClient();
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (!authError && user) {
      const { data: claim } = await (supabase as any)
        .from('owner_claims')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'approved')
        .maybeSingle();
      if (claim) goToDashboard = true;
    }
  } catch {
    // Invalid / expired refresh token → fall through to landing page
  }
  if (goToDashboard) redirect('/owner/dashboard');

  const features = [
    {
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 2h13l4 4v17H3z" /><path d="M7 6h6M7 10h6M7 14h4" />
        </svg>
      ),
      bg: '#fef2f2',
      title: 'Menü Yönetimi',
      desc: 'Ürün ekle, fiyat güncelle, görsel yükle. Değişiklikler anında menüde yansır.',
    },
    {
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#a855f7" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
        </svg>
      ),
      bg: '#faf5ff',
      title: 'Yorum & Mesajlar',
      desc: 'Müşteri yorumlarını oku, yanıtla. Mesajları tek ekrandan yönet.',
    },
    {
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" />
        </svg>
      ),
      bg: '#eff6ff',
      title: 'İstatistikler',
      desc: 'Görüntülenme, favori, yol tarifi ve arama istatistiklerini analiz et.',
    },
    {
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#f97316" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="14" y="14" width="7" height="7" /><path d="M3 17h4m-2-2v4M3 14h7v7" />
        </svg>
      ),
      bg: '#fff7ed',
      title: 'QR Menü',
      desc: 'Masalara özel QR kod oluştur. Müşteriler telefonlarıyla menüye ulaşsın.',
    },
    {
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <polyline points="23 6 13.5 15.5 8.5 10.5 1 18" /><polyline points="17 6 23 6 23 12" />
        </svg>
      ),
      bg: '#f0fdf4',
      title: 'Kampanyalar',
      desc: 'Özel kampanya ve indirimler oluşturarak müşteri sadakatini artır.',
    },
    {
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#6366f1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="12" cy="12" r="3" /><path d="M19.07 4.93a10 10 0 0 1 0 14.14M4.93 4.93a10 10 0 0 0 0 14.14" /><path d="M22.54 6.42a15 15 0 0 1 0 11.16M1.46 6.42a15 15 0 0 0 0 11.16" />
        </svg>
      ),
      bg: '#eef2ff',
      title: 'Yapay Zeka Analizi',
      desc: 'Menün, yorumların ve istatistiklerin AI destekli içgörülerle analiz edilsin.',
    },
  ];

  const steps = [
    { n: '1', title: 'İşletmeni bul veya ekle', desc: 'Yeedoy\'da kayıtlı işletmeni ara ve sahiplenme talebinde bulun ya da yeni ekle.' },
    { n: '2', title: 'Talebini onayla', desc: 'Ekibimiz başvurunu inceler ve 1 iş günü içinde onaylar.' },
    { n: '3', title: 'Panele giriş yap', desc: 'Onay sonrası menü, yorum ve istatistiklere tam erişim kazanırsın.' },
  ];

  const faqs = [
    { q: 'Yeedoy İşletme Paneli ücretli mi?', a: 'Temel özellikler tamamen ücretsizdir. Premium özellikler için uygun fiyatlı planlarımız mevcuttur.' },
    { q: 'İşletmemi nasıl ekleyebilirim?', a: 'Aşağıdaki arama kutusundan işletmeni ara. Listede yoksa "Yeni İşletme Ekle" butonuyla başvuru oluşturabilirsin.' },
    { q: 'Onay ne kadar sürer?', a: 'Sahiplenme talepleri genellikle 1 iş günü içinde değerlendirilir. E-posta ile bilgilendirilirsiniz.' },
    { q: 'Birden fazla işletmem var, ne yapmalıyım?', a: 'Her işletme için ayrı sahiplenme talebi oluşturabilirsiniz. Panel tüm işletmelerinizi tek ekrandan yönetmenize olanak tanır.' },
  ];

  return (
    <div className="flex min-h-screen flex-col bg-white">
      {/* ── Header ── */}
      <header className="sticky top-0 z-50 border-b border-[#f0f0f0] bg-white/95 backdrop-blur-sm px-6 py-4">
        <div className="mx-auto flex max-w-6xl items-center justify-between">
          <Link href="/">
            <YeedoyLogo size={34} />
          </Link>
          <nav className="hidden items-center gap-7 text-sm font-[700] text-[#374151] md:flex">
            <a href="#ozellikler" className="hover:text-[#dc2626] transition">Özellikler</a>
            <a href="#isletme-bul" className="hover:text-[#dc2626] transition">İşletme Bul</a>
            <a href="#nasil-calisir" className="hover:text-[#dc2626] transition">Nasıl Çalışır</a>
            <a href="#destek" className="hover:text-[#dc2626] transition">Destek</a>
          </nav>
          <div className="flex items-center gap-3">
            <Link
              href="/owner/login"
              className="rounded-xl border border-[#e5e7eb] px-4 py-2 text-sm font-[700] text-[#374151] transition hover:border-[#dc2626]/40 hover:text-[#dc2626]"
            >
              Giriş Yap
            </Link>
            <Link
              href="/owner/login#register"
              className="rounded-xl bg-[#dc2626] px-4 py-2 text-sm font-[800] text-white shadow-[0_2px_8px_rgba(220,38,38,0.25)] transition hover:bg-[#b91c1c]"
            >
              Ücretsiz Başla
            </Link>
          </div>
        </div>
      </header>

      {/* ── Hero ── */}
      <section className="relative overflow-hidden bg-white px-6 pb-20 pt-20">
        {/* Decorative background */}
        <div className="pointer-events-none absolute inset-0">
          <div className="absolute -top-32 left-1/2 h-[500px] w-[500px] -translate-x-1/2 rounded-full bg-[#fef2f2] opacity-60 blur-3xl" />
        </div>
        <div className="relative mx-auto max-w-4xl text-center">
          <div className="mb-5 inline-flex items-center gap-2 rounded-full border border-[#fecaca] bg-[#fef2f2] px-4 py-1.5 text-sm font-[700] text-[#dc2626]">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
            </svg>
            Türkiye&apos;nin en kapsamlı işletme yönetim paneli
          </div>
          <h1 className="text-[48px] font-[900] leading-[1.1] tracking-tight text-[#111827] md:text-[60px]">
            İşletmenizi Yeedoy&apos;la
            <br />
            <span className="text-[#dc2626]">dijitalde büyütün</span>
          </h1>
          <p className="mx-auto mt-6 max-w-2xl text-lg leading-relaxed text-[#6b7280]">
            Menü yönetiminden yorumlara, QR koddan kampanyalara — işletmenizin tüm dijital süreçlerini tek panelden kolayca yönetin.
          </p>
          <div className="mt-10 flex flex-wrap items-center justify-center gap-4">
            <Link
              href="/owner/login"
              className="flex h-14 items-center gap-2 rounded-2xl bg-[#dc2626] px-8 text-base font-[800] text-white shadow-[0_4px_16px_rgba(220,38,38,0.30)] transition hover:bg-[#b91c1c] hover:shadow-[0_6px_24px_rgba(220,38,38,0.35)]"
            >
              Ücretsiz Başla
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" />
              </svg>
            </Link>
            <a
              href="#isletme-bul"
              className="flex h-14 items-center gap-2 rounded-2xl border border-[#e5e7eb] px-8 text-base font-[700] text-[#374151] transition hover:bg-[#f9fafb] hover:border-[#d1d5db]"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
              İşletmeni Bul
            </a>
          </div>
          {/* Trust badges */}
          <div className="mt-10 flex flex-wrap items-center justify-center gap-6 text-sm text-[#9ca3af]">
            {['Ücretsiz başla', 'Kredi kartı gerekmez', '1 günde aktif ol', '7/24 destek'].map((t) => (
              <span key={t} className="flex items-center gap-1.5">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <polyline points="20 6 9 17 4 12" />
                </svg>
                {t}
              </span>
            ))}
          </div>
        </div>
      </section>

      {/* ── Features ── */}
      <section id="ozellikler" className="bg-[#fafafa] px-6 py-20">
        <div className="mx-auto max-w-6xl">
          <div className="mb-14 text-center">
            <p className="mb-2 text-sm font-[700] uppercase tracking-widest text-[#dc2626]">Özellikler</p>
            <h2 className="text-4xl font-[900] text-[#111827]">İşletmeniz için ihtiyacınız olan her şey</h2>
            <p className="mx-auto mt-4 max-w-xl text-[#6b7280]">
              Yeedoy İşletme Paneli, restoranınızın dijital yönetimini en verimli hale getirmek için tasarlandı.
            </p>
          </div>
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {features.map((f) => (
              <div key={f.title} className="rounded-2xl border border-[#f0f0f0] bg-white p-6 shadow-sm transition hover:shadow-md hover:-translate-y-0.5">
                <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-2xl" style={{ background: f.bg }}>
                  {f.icon}
                </div>
                <h3 className="mb-2 text-base font-[800] text-[#111827]">{f.title}</h3>
                <p className="text-sm leading-relaxed text-[#6b7280]">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Business finder ── */}
      <section id="isletme-bul" className="px-6 py-20">
        <div className="mx-auto max-w-3xl">
          <div className="mb-10 text-center">
            <p className="mb-2 text-sm font-[700] uppercase tracking-widest text-[#dc2626]">İşletme Bul</p>
            <h2 className="text-4xl font-[900] text-[#111827]">İşletmenizi Yeedoy&apos;da bulun</h2>
            <p className="mx-auto mt-4 max-w-lg text-[#6b7280]">
              Yeedoy&apos;da kayıtlı işletmenizi arayın ve sahiplenme talebinde bulunun. Kısa sürede panelinize erişin.
            </p>
          </div>
          <OwnerLandingSearch />
          <div className="mt-6 text-center text-sm text-[#6b7280]">
            İşletmeniz listede yok mu?{' '}
            <Link href="/owner/businesses/new" className="font-[700] text-[#dc2626] hover:underline">
              Yeni işletme ekle →
            </Link>
          </div>
        </div>
      </section>

      {/* ── How it works ── */}
      <section id="nasil-calisir" className="bg-[#fafafa] px-6 py-20">
        <div className="mx-auto max-w-5xl">
          <div className="mb-14 text-center">
            <p className="mb-2 text-sm font-[700] uppercase tracking-widest text-[#dc2626]">Nasıl Çalışır</p>
            <h2 className="text-4xl font-[900] text-[#111827]">3 adımda başlayın</h2>
          </div>
          <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
            {steps.map((s, i) => (
              <div key={s.n} className="relative flex flex-col items-center text-center">
                {i < steps.length - 1 && (
                  <div className="absolute left-[calc(50%+40px)] top-6 hidden h-0.5 w-[calc(100%-80px)] bg-[#fee2e2] md:block" />
                )}
                <div className="mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-[#dc2626] text-xl font-[900] text-white shadow-[0_4px_16px_rgba(220,38,38,0.30)]">
                  {s.n}
                </div>
                <h3 className="mb-2 text-base font-[800] text-[#111827]">{s.title}</h3>
                <p className="text-sm leading-relaxed text-[#6b7280]">{s.desc}</p>
              </div>
            ))}
          </div>
          <div className="mt-12 text-center">
            <Link
              href="/owner/login"
              className="inline-flex h-12 items-center gap-2 rounded-xl bg-[#dc2626] px-8 text-sm font-[800] text-white shadow-[0_2px_8px_rgba(220,38,38,0.28)] transition hover:bg-[#b91c1c]"
            >
              Hemen Başla
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" />
              </svg>
            </Link>
          </div>
        </div>
      </section>

      {/* ── Support / FAQ ── */}
      <section id="destek" className="px-6 py-20">
        <div className="mx-auto max-w-3xl">
          <div className="mb-12 text-center">
            <p className="mb-2 text-sm font-[700] uppercase tracking-widest text-[#dc2626]">Destek</p>
            <h2 className="text-4xl font-[900] text-[#111827]">Sık sorulan sorular</h2>
          </div>
          <div className="divide-y divide-[#f3f4f6] rounded-2xl border border-[#f0f0f0] bg-white">
            {faqs.map((faq) => (
              <details key={faq.q} className="group p-6">
                <summary className="flex cursor-pointer list-none items-center justify-between gap-4">
                  <span className="text-sm font-[800] text-[#111827]">{faq.q}</span>
                  <span className="flex-shrink-0 transition group-open:rotate-45">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                      <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
                    </svg>
                  </span>
                </summary>
                <p className="mt-3 text-sm leading-relaxed text-[#6b7280]">{faq.a}</p>
              </details>
            ))}
          </div>

          {/* Support CTA */}
          <div className="mt-10 rounded-2xl border border-[#f0f0f0] bg-[#fafafa] p-8 text-center">
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-[#f3f4f6]">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#374151" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M3 18v-6a9 9 0 0 1 18 0v6" />
                <path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z" />
              </svg>
            </div>
            <h3 className="text-base font-[800] text-[#111827]">Hâlâ sorunuz mu var?</h3>
            <p className="mt-2 text-sm text-[#6b7280]">Destek ekibimiz size yardımcı olmaktan mutluluk duyar.</p>
            <div className="mt-5 flex flex-wrap items-center justify-center gap-3">
              <a href="mailto:destek@yeedoy.com"
                className="flex h-11 items-center gap-2 rounded-xl border border-[#e5e7eb] bg-white px-5 text-sm font-[700] text-[#374151] transition hover:bg-[#f9fafb]">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" /><polyline points="22,6 12,13 2,6" />
                </svg>
                E-posta Gönder
              </a>
              <a href="#"
                className="flex h-11 items-center gap-2 rounded-xl bg-[#dc2626] px-5 text-sm font-[800] text-white transition hover:bg-[#b91c1c]">
                Canlı Destek
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="border-t border-[#f0f0f0] bg-white px-6 py-8">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-6">
          <div className="flex items-center gap-3">
            <YeedoyLogo size={28} />
            <span className="text-xs text-[#9ca3af]">İşletme Paneli</span>
          </div>
          <div className="flex flex-wrap gap-6 text-xs text-[#9ca3af]">
            <Link href="/legal" className="hover:text-[#374151] transition">Kullanım Koşulları</Link>
            <Link href="/legal" className="hover:text-[#374151] transition">Gizlilik Politikası</Link>
            <a href="#" className="hover:text-[#374151] transition">Yardım Merkezi</a>
          </div>
          <span className="text-xs text-[#9ca3af]">© 2024 Yeedoy. Tüm hakları saklıdır.</span>
        </div>
      </footer>
    </div>
  );
}
