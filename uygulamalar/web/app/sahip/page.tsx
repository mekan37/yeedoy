import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { redirect } from 'next/navigation';
import {
  ArrowRight,
  BadgeCheck,
  Camera,
  CheckCircle2,
  Crown,
  LineChart,
  QrCode,
  Search,
  Sparkles,
  TrendingUp,
  X,
} from 'lucide-react';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';
import { OwnerLandingSearch } from './sahip-arama';
import { PLAN_TANIMLARI, type PlanTierId } from '@/src/lib/plan/plan-tanimlari';

export const metadata: Metadata = {
  title: 'İşletme Paneli',
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
      const { data: claim } = await (supabase)
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
  if (goToDashboard) redirect('/sahip/gosterge-panosu');

  const freeIncludes = [
    { title: '30 ürüne kadar menü', desc: 'Ürün ekleyin, fiyat güncelleyin, görsel yükleyin; değişiklikler anında yayında.' },
    { title: 'Ayda 1 fotoğraftan menü tarama', desc: 'Kağıt menünüzün fotoğrafını çekin, ürünleri sizin yerinize ayıklayalım.' },
    { title: '1 menü dili', desc: 'Menünüzü tek dilde (ör. Türkçe) yayınlayın.' },
    { title: 'QR kodunuz hazır', desc: 'Masalara özel QR kod üretin (Yeedoy filigranıyla).' },
    { title: 'Son 7 günün istatistikleri', desc: 'Görüntülenme, favori ve yol tarifi verilerini takip edin.' },
    { title: '1 ekip koltuğu', desc: 'İşletme sahibi olarak panele tam erişimle giriş yaparsınız.' },
  ];

  const premiumOnly = [
    'Sınırsız ürün ve fotoğraftan menü taraması',
    'AI alerjen/kalori otomasyonu',
    'Filigransız QR + haritada/keşifte öne çıkarma',
    'Sadakat programı ve kampanyalar',
    'Daha fazla ekip koltuğu, daha uzun analiz geçmişi',
  ];

  const paidPlans = PLAN_TANIMLARI.filter((p) => p.id !== 'free');
  const planHighlights: Record<Exclude<PlanTierId, 'free'>, string[]> = {
    starter: [
      'Sınırsız menü ürünü',
      'Ayda 5 fotoğraftan menü taraması',
      'Filigransız QR kod',
      '3 ekip koltuğu · son 30 gün analiz',
    ],
    standard: [
      'Sınırsız OCR taraması + AI alerjen/kalori otomasyonu',
      '2 menü dili · haritada/keşifte öne çıkarma',
      'Sadakat programı · ayda 5 kampanya',
      '10 ekip koltuğu · 3 şube · son 90 gün analiz',
    ],
    pro: [
      'AI ile ürün görseli üretme',
      'Sınırsız dil, ekip ve şube',
      'Sınırsız kampanya',
      'Tüm Standart özellikleri dahil',
    ],
  };

  const steps = [
    { icon: <Search size={18} aria-hidden="true" />, n: '1', title: 'İşletmeni bul veya ekle', desc: "Yeedoy'da kayıtlı işletmeni ara ve sahiplenme talebinde bulun ya da yeni ekle." },
    { icon: <BadgeCheck size={18} aria-hidden="true" />, n: '2', title: 'Talebini onayla', desc: 'Ekibimiz başvurunu inceler ve 1 iş günü içinde onaylar.' },
    { icon: <LineChart size={18} aria-hidden="true" />, n: '3', title: 'Panele giriş yap', desc: 'Onay sonrası menü, yorum ve istatistiklere tam erişim kazanırsın — ücretsiz kademeyle.' },
  ];

  const faqs = [
    {
      q: 'Yeedoy İşletme Paneli ücretli mi?',
      a: 'Hayır. Her işletme, 30 ürüne kadar menü, ayda 1 fotoğraftan menü tarama ve filigranlı QR kod dahil ücretsiz kademeyle başlar — kart bilgisi istemiyoruz. Menü limitini kaldırmak, AI otomasyonlarını açmak ya da haritada öne çıkmak isterseniz 99₺/ay\'dan başlayan üç premium kadememiz var (yukarıya bakın).',
    },
    { q: 'İşletmemi nasıl ekleyebilirim?', a: 'Aşağıdaki arama kutusundan işletmeni ara. Listede yoksa "Yeni İşletme Ekle" butonuyla başvuru oluşturabilirsin.' },
    { q: 'Onay ne kadar sürer?', a: 'Sahiplenme talepleri genellikle 1 iş günü içinde değerlendirilir. E-posta ile bilgilendirilirsiniz.' },
    { q: 'Premium\'a nasıl geçerim?', a: 'Ödeme entegrasyonumuz şu an devrede değil. Panelinizden yükseltme talebi oluşturursunuz, destek ekibimiz size dönüş yapar ve kademenizi birlikte etkinleştiririz.' },
    { q: 'Birden fazla işletmem var, ne yapmalıyım?', a: 'Her işletme için ayrı sahiplenme talebi oluşturabilirsiniz. Panel tüm işletmelerinizi tek ekrandan yönetmenize olanak tanır.' },
  ];

  return (
    <div className="flex min-h-screen flex-col bg-card">
      {/* ── Header ── */}
      <header className="sticky top-0 z-50 border-b border-border bg-card/95 backdrop-blur-xs px-6 py-4">
        <div className="mx-auto flex max-w-6xl items-center justify-between">
          <Link href="/">
            <YeedoyLogo size={34} />
          </Link>
          <nav className="hidden items-center gap-7 text-sm font-bold text-text md:flex">
            <a href="#ucretsiz" className="transition hover:text-primary">Ücretsiz &amp; Premium</a>
            <a href="#isletme-bul" className="transition hover:text-primary">İşletme Bul</a>
            <a href="#nasil-calisir" className="transition hover:text-primary">Nasıl Çalışır</a>
            <a href="#sss" className="transition hover:text-primary">SSS</a>
          </nav>
          <div className="flex items-center gap-3">
            <Link
              href="/giris"
              className="rounded-xl border border-border px-4 py-2 text-sm font-bold text-text transition hover:border-primary/40 hover:text-primary"
            >
              Giriş Yap
            </Link>
            <Link
              href="/giris?tab=kayit"
              className="rounded-xl bg-primary px-4 py-2 text-sm font-extrabold text-white shadow-yd1 transition hover:brightness-105"
            >
              Ücretsiz Başla
            </Link>
          </div>
        </div>
      </header>

      {/* ── Hero ── */}
      <section className="relative overflow-hidden bg-card px-6 pb-16 pt-16 lg:pb-24 lg:pt-20">
        {/* Decorative background */}
        <div className="pointer-events-none absolute inset-0">
          <div className="absolute -top-32 left-1/2 h-[500px] w-[500px] -translate-x-1/2 rounded-full bg-(--yd-color-primary-soft) opacity-60 blur-3xl lg:left-1/4" />
        </div>
        <div className="relative mx-auto grid max-w-6xl gap-12 lg:grid-cols-[1.05fr_0.95fr] lg:items-center">
          {/* Left — copy */}
          <div className="text-center lg:text-left">
            <div className="mb-5 inline-flex items-center gap-2 rounded-full border border-primary/25 bg-primary/10 px-4 py-1.5 text-sm font-bold text-primary">
              <Sparkles size={14} aria-hidden="true" />
              Türkiye&apos;nin en kapsamlı işletme yönetim paneli
            </div>
            <h1 className="text-[42px] font-black leading-[1.1] tracking-tight text-textStrong sm:text-[52px] lg:text-[56px]">
              İşletmenizi Yeedoy&apos;a taşıyın,
              <br />
              <span className="text-primary">bugün, ücretsiz</span>
            </h1>
            <p className="mx-auto mt-6 max-w-xl text-lg leading-relaxed text-muted lg:mx-0">
              30 ürüne kadar menü, sınırsız QR kod ve anlık istatistikler — kart bilgisi istemeden, dakikalar içinde kurulur. Büyüdükçe premium kademelerle sınırları kaldırırsınız.
            </p>
            <div className="mt-10 flex flex-wrap items-center justify-center gap-4 lg:justify-start">
              <Link
                href="/giris?tab=kayit"
                className="flex h-14 items-center gap-2 rounded-2xl bg-primary px-8 text-base font-extrabold text-white shadow-yd2 transition hover:brightness-105"
              >
                Ücretsiz Başla
                <ArrowRight size={18} aria-hidden="true" />
              </Link>
              <a
                href="#isletme-bul"
                className="flex h-14 items-center gap-2 rounded-2xl border border-border px-8 text-base font-bold text-text transition hover:bg-cardAlt hover:border-borderStrong"
              >
                <Search size={18} aria-hidden="true" />
                İşletmeni Bul
              </a>
            </div>
            {/* Trust badges */}
            <div className="mt-10 flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-sm text-muted lg:justify-start">
              {['Kredi kartı gerekmez', '30 ürüne kadar ücretsiz', 'Dakikalar içinde kurulum', 'İstediğinizde yükseltin'].map((t) => (
                <span key={t} className="flex items-center gap-1.5">
                  <CheckCircle2 size={14} className="text-success" aria-hidden="true" />
                  {t}
                </span>
              ))}
            </div>
          </div>

          {/* Right — product preview mockup (illustrative, not a literal screenshot) */}
          <div className="landing-product-stage relative hidden lg:flex lg:items-center lg:justify-center" aria-hidden="true">
            <div className="landing-device relative w-full max-w-sm rounded-[28px] border border-border bg-card p-1.5 shadow-yd3">
              <div className="overflow-hidden rounded-[22px] border border-border bg-cardAlt">
                {/* fake browser chrome */}
                <div className="flex items-center gap-1.5 border-b border-border bg-card px-4 py-3">
                  <span className="h-2.5 w-2.5 rounded-full bg-border" />
                  <span className="h-2.5 w-2.5 rounded-full bg-border" />
                  <span className="h-2.5 w-2.5 rounded-full bg-border" />
                  <span className="ml-2 text-[11px] font-bold text-muted">yeedoy.com/sahip</span>
                </div>
                <div className="relative overflow-hidden p-4">
                  <div className="landing-scan-line" />
                  <div className="mb-3 flex items-center gap-2 rounded-xl border border-dashed border-borderStrong bg-card px-3 py-2.5">
                    <Camera size={14} className="text-muted" aria-hidden="true" />
                    <span className="text-[11px] font-bold text-muted">Menü fotoğrafı taranıyor…</span>
                  </div>
                  {[
                    { name: 'Adana Kebap', price: '₺320' },
                    { name: 'Mercimek Çorbası', price: '₺90' },
                    { name: 'Ayran', price: '₺40' },
                  ].map((item, i) => (
                    <div
                      key={item.name}
                      className="landing-detail-row mb-2 flex items-center justify-between rounded-xl bg-card px-3 py-2.5 shadow-yd1"
                      style={{ animationDelay: `${420 + i * 140}ms` }}
                    >
                      <span className="text-xs font-extrabold text-textStrong">{item.name}</span>
                      <span className="text-xs font-black text-primary">{item.price}</span>
                    </div>
                  ))}
                  <div className="landing-detail-row mt-3 flex flex-wrap items-center gap-2" style={{ animationDelay: '840ms' }}>
                    <span className="flex items-center gap-1 rounded-full bg-success/10 px-2.5 py-1 text-[10px] font-extrabold text-success">
                      <TrendingUp size={11} aria-hidden="true" /> +18% görüntülenme
                    </span>
                    <span className="flex items-center gap-1 rounded-full bg-primary/10 px-2.5 py-1 text-[10px] font-extrabold text-primary">
                      <QrCode size={11} aria-hidden="true" /> QR hazır
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <div className="absolute -left-6 -top-4 flex items-center gap-2 rounded-2xl border border-border bg-card px-3 py-2 shadow-yd2">
              <Sparkles size={14} className="text-primary" aria-hidden="true" />
              <span className="text-[11px] font-extrabold text-textStrong">Dakikalar içinde menü kurun</span>
            </div>
          </div>
        </div>
      </section>

      {/* ── Ücretsiz kademe ── */}
      <section id="ucretsiz" className="bg-cardAlt px-6 py-20">
        <div className="mx-auto max-w-6xl">
          <div className="mb-12 max-w-2xl">
            <p className="mb-2 text-sm font-bold uppercase tracking-widest text-primary">Ücretsiz Kademe</p>
            <h2 className="text-4xl font-black text-textStrong">Bugün başlayın, kart bilgisi istemeyiz</h2>
            <p className="mt-4 text-muted">
              Yeedoy&apos;da her işletme ücretsiz kademeyle başlar. Aşağıdakiler soyut vaatler değil — tam olarak
              anında erişeceğiniz şeyler:
            </p>
          </div>
          <div className="grid gap-6 lg:grid-cols-[1.4fr_1fr]">
            {/* Included */}
            <div className="rounded-[24px] border border-border bg-card p-6 shadow-yd1 sm:p-8">
              <div className="grid gap-5 sm:grid-cols-2">
                {freeIncludes.map((f) => (
                  <div key={f.title} className="flex items-start gap-3">
                    <span className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-success/10 text-success">
                      <CheckCircle2 size={16} aria-hidden="true" />
                    </span>
                    <div>
                      <p className="text-sm font-extrabold text-textStrong">{f.title}</p>
                      <p className="mt-0.5 text-xs leading-relaxed text-muted">{f.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* What premium unlocks — teaser */}
            <div className="rounded-[24px] border border-border bg-card p-6 shadow-yd1 sm:p-8">
              <p className="mb-4 flex items-center gap-1.5 text-xs font-black uppercase tracking-wide text-muted">
                <Crown size={14} className="text-primary" aria-hidden="true" />
                Premium&apos;da açılır
              </p>
              <div className="space-y-3">
                {premiumOnly.map((t) => (
                  <div key={t} className="flex items-start gap-2.5">
                    <X size={14} className="mt-0.5 shrink-0 text-muted/60" aria-hidden="true" />
                    <span className="text-sm text-muted">{t}</span>
                  </div>
                ))}
              </div>
              <a
                href="#fiyatlandirma"
                className="landing-link mt-6 inline-flex items-center gap-1.5 text-sm font-extrabold text-primary"
              >
                Kademeleri karşılaştırın <ArrowRight size={14} aria-hidden="true" />
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* ── Fiyatlandırma / Premium ── */}
      <section id="fiyatlandirma" className="bg-card px-6 py-20">
        <div className="mx-auto max-w-6xl">
          <div className="mb-14 text-center">
            <p className="mb-2 text-sm font-bold uppercase tracking-widest text-primary">Premium</p>
            <h2 className="text-4xl font-black text-textStrong">Büyüdükçe kademe atlayın</h2>
            <p className="mx-auto mt-4 max-w-xl text-muted">
              Üç kademe, farklı büyüklükteki işletmeler için tasarlandı. İhtiyacınız değiştikçe kademe değiştirebilirsiniz.
            </p>
          </div>
          <div className="grid gap-5 sm:grid-cols-3">
            {paidPlans.map((plan) => (
              <div
                key={plan.id}
                className={
                  plan.highlight
                    ? 'relative flex flex-col gap-5 rounded-[24px] border border-primary/40 bg-primary/5 p-6 shadow-yd2'
                    : 'relative flex flex-col gap-5 rounded-[24px] border border-border bg-card p-6 shadow-yd1'
                }
              >
                {plan.highlight && (
                  <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-(--yd-color-primary) px-3 py-1 text-[10px] font-extrabold uppercase tracking-wide text-white">
                    En Popüler
                  </span>
                )}
                <div>
                  <p className="text-base font-black text-textStrong">{plan.label}</p>
                  <p className="text-xs text-muted">{plan.tagline}</p>
                </div>
                <div>
                  <span className="text-3xl font-black text-textStrong">₺{plan.monthlyPrice.toLocaleString('tr-TR')}</span>
                  <span className="text-xs font-bold text-muted"> /ay</span>
                </div>
                <ul className="flex flex-1 flex-col gap-2.5 border-t border-border pt-4">
                  {planHighlights[plan.id as Exclude<PlanTierId, 'free'>].map((h) => (
                    <li key={h} className="flex items-start gap-2 text-xs leading-relaxed text-text">
                      <CheckCircle2 size={14} className="mt-0.5 shrink-0 text-success" aria-hidden="true" />
                      {h}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
          <div className="mt-10 flex flex-col items-center gap-3 text-center">
            <Link
              href="/giris?tab=kayit"
              className="flex h-12 items-center gap-2 rounded-xl bg-primary px-8 text-sm font-extrabold text-white shadow-yd1 transition hover:brightness-105"
            >
              Ücretsiz kaydolun, istediğinizde yükseltin
              <ArrowRight size={16} aria-hidden="true" />
            </Link>
            <Link href="/fiyatlandirma" className="landing-link text-sm font-extrabold text-primary">
              Tüm özellikleri kademe kademe karşılaştırın →
            </Link>
            <p className="mt-1 max-w-md text-xs text-muted">
              Ödeme entegrasyonumuz henüz devrede değil — yükseltme talebiniz destek ekibimize düşer, kısa sürede size dönüş yaparız.
            </p>
          </div>
        </div>
      </section>

      {/* ── Business finder ── */}
      <section id="isletme-bul" className="bg-cardAlt px-6 py-20">
        <div className="mx-auto max-w-3xl">
          <div className="mb-10 text-center">
            <p className="mb-2 text-sm font-bold uppercase tracking-widest text-primary">İşletme Bul</p>
            <h2 className="text-4xl font-black text-textStrong">İşletmenizi Yeedoy&apos;da bulun</h2>
            <p className="mx-auto mt-4 max-w-lg text-muted">
              Yeedoy&apos;da kayıtlı işletmenizi arayın ve sahiplenme talebinde bulunun. Kısa sürede panelinize erişin.
            </p>
          </div>
          <div className="rounded-[24px] border border-border bg-card p-5 shadow-yd1 sm:p-8">
            <OwnerLandingSearch />
          </div>
          <div className="mt-6 text-center text-sm text-muted">
            İşletmeniz listede yok mu?{' '}
            <Link href="/sahiplen/yeni" className="font-bold text-primary hover:underline">
              Yeni işletme ekle →
            </Link>
          </div>
        </div>
      </section>

      {/* ── How it works ── */}
      <section id="nasil-calisir" className="bg-card px-6 py-20">
        <div className="mx-auto max-w-5xl">
          <div className="mb-14 text-center">
            <p className="mb-2 text-sm font-bold uppercase tracking-widest text-primary">Nasıl Çalışır</p>
            <h2 className="text-4xl font-black text-textStrong">3 adımda başlayın</h2>
          </div>
          <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
            {steps.map((s, i) => (
              <div key={s.n} className="relative flex flex-col items-center text-center">
                {i < steps.length - 1 && (
                  <div className="absolute left-[calc(50%+40px)] top-6 hidden h-0.5 w-[calc(100%-80px)] bg-primary/15 md:block" />
                )}
                <div className="mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-primary text-white shadow-yd2">
                  {s.icon}
                </div>
                <h3 className="mb-2 text-base font-extrabold text-textStrong">{s.title}</h3>
                <p className="text-sm leading-relaxed text-muted">{s.desc}</p>
              </div>
            ))}
          </div>
          <div className="mt-12 text-center">
            <Link
              href="/giris?tab=kayit"
              className="inline-flex h-12 items-center gap-2 rounded-xl bg-primary px-8 text-sm font-extrabold text-white shadow-yd1 transition hover:brightness-105"
            >
              Hemen Başla
              <ArrowRight size={16} aria-hidden="true" />
            </Link>
          </div>
        </div>
      </section>

      {/* ── Support / FAQ ── */}
      <section id="sss" className="bg-cardAlt px-6 py-20">
        <div className="mx-auto max-w-3xl">
          <div className="mb-12 text-center">
            <p className="mb-2 text-sm font-bold uppercase tracking-widest text-primary">Destek</p>
            <h2 className="text-4xl font-black text-textStrong">Sık sorulan sorular</h2>
          </div>
          <div className="divide-y divide-border rounded-[24px] border border-border bg-card">
            {faqs.map((faq) => (
              <details key={faq.q} className="group p-6">
                <summary className="flex cursor-pointer list-none items-center justify-between gap-4">
                  <span className="text-sm font-extrabold text-textStrong">{faq.q}</span>
                  <span className="shrink-0 text-muted transition group-open:rotate-45">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                      <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
                    </svg>
                  </span>
                </summary>
                <p className="mt-3 text-sm leading-relaxed text-muted">{faq.a}</p>
              </details>
            ))}
          </div>

          {/* Support CTA */}
          <div className="mt-10 rounded-[24px] border border-border bg-card p-8 text-center">
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-cardAlt">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-text">
                <path d="M3 18v-6a9 9 0 0 1 18 0v6" />
                <path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z" />
              </svg>
            </div>
            <h3 className="text-base font-extrabold text-textStrong">Hâlâ sorunuz mu var?</h3>
            <p className="mt-2 text-sm text-muted">Destek ekibimiz size yardımcı olmaktan mutluluk duyar.</p>
            <div className="mt-5 flex flex-wrap items-center justify-center gap-3">
              <a href="mailto:destek@yeedoy.com"
                className="flex h-11 items-center gap-2 rounded-xl border border-border bg-card px-5 text-sm font-bold text-text transition hover:bg-cardAlt">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" /><polyline points="22,6 12,13 2,6" />
                </svg>
                E-posta Gönder
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="border-t border-border bg-card px-6 py-8">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-6">
          <div className="flex items-center gap-3">
            <YeedoyLogo size={28} />
            <span className="text-xs text-muted">İşletme Paneli</span>
          </div>
          <div className="flex flex-wrap gap-6 text-xs text-muted">
            <Link href="/yasal/terms" className="transition hover:text-text">Kullanım Koşulları</Link>
            <Link href="/yasal/privacy" className="transition hover:text-text">Gizlilik Politikası</Link>
          </div>
          <span className="text-xs text-muted">© 2026 Yeedoy. Tüm hakları saklıdır.</span>
        </div>
      </footer>
    </div>
  );
}
