import type { Metadata } from 'next';
import Link from 'next/link';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container, Badge, SectionHeader } from '@/src/ui/acik/ortak';
import { appConfig } from '@/src/lib/ayarlar';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export const revalidate = 3600;

const SITE_URL = () => appConfig.siteUrl().replace(/\/$/, '');

export const metadata: Metadata = {
  title: 'Türkiye Restoran Fiyat Endeksi | Yeedoy',
  description:
    'Yeedoy, Türkiye genelindeki restoran menü fiyatlarını topluluk doğrulamasıyla izleyen bağımsız fiyat endeksidir. Aylık yayınlanır — medya ve araştırmacılar için ücretsiz.',
  alternates: { canonical: `${SITE_URL()}/fiyat-endeksi` },
  robots: { index: true, follow: true },
  openGraph: {
    title: 'Türkiye Restoran Fiyat Endeksi | Yeedoy',
    description:
      'Yeedoy, Türkiye genelindeki restoran menü fiyatlarını topluluk doğrulamasıyla izleyen bağımsız fiyat endeksidir.',
    url: `${SITE_URL()}/fiyat-endeksi`,
    locale: 'tr_TR',
    type: 'website',
  },
};

// ── Tipler ────────────────────────────────────────────────────────────────────

type PriceRow = {
  category: string;
  median_price_cents: number;
  avg_price_cents: number;
  sample_count: number;
  updated_in_30d: number;
};

// ── Yardımcı ─────────────────────────────────────────────────────────────────

function formatTL(cents: number) {
  return `₺${(cents / 100).toLocaleString('tr-TR', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  })}`;
}

// ── Statik içerik sabitleri ───────────────────────────────────────────────────

const WHY_NOW_CARDS = [
  {
    eyebrow: 'Bağlam',
    title: 'Gıda Enflasyonu',
    body: 'Türkiye\'de gıda fiyat enflasyonu son 67 aydır kesintisiz yükselmektedir. Bu ortamda tüketiciler menü fiyatlarını güvenilir bir kaynaktan takip edememektedir.',
    icon: (
      <svg viewBox="0 0 40 40" className="h-8 w-8" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="6 34 14 20 22 26 32 10" />
        <line x1="6" y1="34" x2="34" y2="34" />
      </svg>
    ),
  },
  {
    eyebrow: 'Sorun',
    title: 'Fiyat Şeffaflığı Eksikliği',
    body: 'Sipariş platformları teslimat marjını içerir. Google Maps ve TripAdvisor\'daki fiyat bilgileri aylarca eski kalabilmektedir. Tarihsel karşılaştırma ya da güven skoru içermeyen bu kaynaklar yetersiz kalmaktadır.',
    icon: (
      <svg viewBox="0 0 40 40" className="h-8 w-8" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="20" cy="20" r="14" />
        <line x1="20" y1="12" x2="20" y2="22" />
        <circle cx="20" cy="28" r="1.5" fill="currentColor" stroke="none" />
      </svg>
    ),
  },
  {
    eyebrow: 'Çözüm',
    title: 'Yeedoy Fiyat Endeksi',
    body: 'Topluluk tarafından doğrulanmış gerçek zamanlı fiyatlar, tarihsel fiyat trendi ve ilçe bazlı karşılaştırma. Türkiye\'de bu özelliklerin bütününü bir arada sunan tek bağımsız platform.',
    icon: (
      <svg viewBox="0 0 40 40" className="h-8 w-8" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M20 4 L24 14 L36 14 L26 21 L30 32 L20 25 L10 32 L14 21 L4 14 L16 14 Z" />
      </svg>
    ),
  },
];

const HOW_STEPS = [
  {
    step: '1',
    title: 'İşletme Menüsünü Günceller',
    body: 'İşletme sahipleri kendi Yeedoy panelinden menü fiyatlarını doğrudan günceller. Güncel fiyat anında toplulukla paylaşılır.',
  },
  {
    step: '2',
    title: 'Topluluk Doğrular',
    body: 'Doğrulanmış ziyaret rozetine sahip kullanıcılar fiyat değişikliklerini bildirir. Her bildirim güven skoru ile ağırlıklandırılır.',
  },
  {
    step: '3',
    title: 'Endeks Hesaplanır',
    body: 'Minimum örnek büyüklüğüne ulaşan kategoriler için medyan fiyat, ortalama ve aylık değişim oranı hesaplanarak endekse dahil edilir.',
  },
];

const PRICE_LEVELS = [
  {
    symbol: '₺',
    label: 'Uygun',
    desc: 'Kahve, çay, simit ve hafif atıştırmalıklar. Ortalama masa tutarı yaklaşık 100–250 TL aralığında.',
  },
  {
    symbol: '₺₺',
    label: 'Orta',
    desc: 'Döner, pide, burger, pizza ve kasap menüleri. Ortalama masa tutarı yaklaşık 250–600 TL aralığında.',
  },
  {
    symbol: '₺₺₺',
    label: 'Üst Segment',
    desc: 'Fine dining, alkollü içki servisi yapan mekanlar ve steakhouse\'lar. Ortalama masa tutarı 600 TL üzeri.',
  },
];

const DATA_STORIES = [
  {
    title: 'İstanbul\'da Menü Fiyatları 6 Ayda Ne Kadar Değişti?',
    body: 'İstanbul genelindeki restoran fiyatlarının yarı yıllık değişimini kategori bazında analiz ediyoruz. En yüksek artış hangi kategoride, en istikrarlı fiyatlar nerede?',
    score: '5/5 Medya Çekiciliği',
  },
  {
    title: 'En Uygun Semtler: İlçe Bazlı Fiyat Kıyaslaması',
    body: 'Şehrinizde en uygun yemek yenebilen ilçeleri ve en pahalı semtleri karşılaştırıyoruz. İlçe bazlı medyan fiyat analizi harita formatında.',
    score: '5/5 Medya Çekiciliği',
  },
  {
    title: 'Kategori Bazlı Endeks: Kahve vs. Burger vs. Pizza',
    body: 'Türkiye\'de restoran enflasyonunu ürün grupları bazında inceliyoruz. Kahve mi pahalılaştı, kebap mı? Standart ürünler üzerinden karşılaştırmalı analiz.',
    score: '4/5 Medya Çekiciliği',
  },
  {
    title: 'Doğrulanmış Ziyaret: Güvenilir Fiyat Verisi Neden Önemli?',
    body: 'Yeedoy\'un topluluk doğrulama sistemi sahte fiyat bildirimlerini nasıl filtreler? Doğrulanmış ziyaretçi bildirimlerinin kabul oranı vs. genel kullanıcı oranı.',
    score: '3/5 Medya Çekiciliği',
  },
  {
    title: 'Zincir vs. Bağımsız: Fiyat Farkı',
    body: 'Büyük zincirler mi daha ucuz, yoksa bağımsız kafeler mi? Tüketicinin en sık sorduğu soruyu veriye dayalı olarak yanıtlıyoruz.',
    score: '4/5 Medya Çekiciliği',
  },
];

const CTA_BLOCKS = [
  {
    eyebrow: 'Medya ve Araştırmacılar',
    title: 'Veri Alıntısı ve İşbirliği',
    body: 'Bu endeksin verileri "Yeedoy Restoran Fiyat Endeksi" adıyla kaynak gösterilerek serbestçe kullanılabilir. Metodoloji, ham veri veya röportaj talepleriniz için iletişime geçin.',
    cta: 'veri@yeedoy.com',
    ctaHref: 'mailto:veri@yeedoy.com',
    ctaVariant: 'mail' as const,
  },
  {
    eyebrow: 'İşletme Sahipleri',
    title: 'Menünüzü Güncel Tutun',
    body: 'Menü fiyatlarınızı siz güncelleyin — kullanıcılar doğru fiyatı görsün. İşletmenizi Yeedoy\'a ekleyin, sahiplik talebinde bulunun.',
    cta: 'İşletme Paneline Git',
    ctaHref: '/isletme',
    ctaVariant: 'link' as const,
  },
  {
    eyebrow: 'Kullanıcılar',
    title: 'Yakınızdaki Fiyatları Keşfedin',
    body: 'Şehrinizde en iyi değeri sunan restoranları bulun. Bütçenize göre filtreleyin, topluluk tarafından doğrulanmış fiyatlara güvenin.',
    cta: 'Keşfetmeye Başla',
    ctaHref: '/kesif',
    ctaVariant: 'link' as const,
  },
];

// ── Sayfa ─────────────────────────────────────────────────────────────────────

export default async function FiyatEndeksiPage() {
  const supabase = createSupabasePublicClient();
  const siteUrl = SITE_URL();

  // Canlı veri: get_regional_price_index_v2 anon GRANT mevcut
  const { data } = await (supabase as any).rpc('get_regional_price_index_v2', {
    p_city: null,
    p_district: null,
    p_limit: 20,
  }) as { data: PriceRow[] | null };

  const rows = (data ?? []).filter((r) => r.sample_count >= 3);
  const totalSamples = rows.reduce((s, r) => s + r.sample_count, 0);
  const totalUpdated = rows.reduce((s, r) => s + r.updated_in_30d, 0);
  const hasData = rows.length > 0;

  const now = new Date();
  const ay = now.toLocaleDateString('tr-TR', { month: 'long', year: 'numeric' });

  // JSON-LD: Dataset schema
  const schema = {
    '@context': 'https://schema.org',
    '@type': 'Dataset',
    name: `Türkiye Restoran Fiyat Endeksi — ${ay}`,
    description:
      'Yeedoy kullanıcıları tarafından doğrulanmış aylık restoran fiyat endeksi verisi. Topluluk güven skoru ve tarihsel fiyat trendi içerir.',
    url: `${siteUrl}/fiyat-endeksi`,
    publisher: {
      '@type': 'Organization',
      name: 'Yeedoy',
      url: siteUrl,
    },
    temporalCoverage: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`,
    spatialCoverage: { '@type': 'Place', name: 'Türkiye' },
    license: 'https://creativecommons.org/licenses/by/4.0/',
    isAccessibleForFree: true,
  };

  return (
    <PublicShell>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
      />

      {/* ── Hero ──────────────────────────────────────────────────────────── */}
      <section className="border-b border-border bg-card">
        <Container className="py-16 text-center">
          <p className="mb-3 text-xs font-extrabold uppercase tracking-widest text-primary">
            Türkiye · Bağımsız · Topluluk Destekli
          </p>
          <h1 className="mb-4 text-4xl font-black leading-tight tracking-tight text-textStrong sm:text-5xl">
            Türkiye Restoran
            <br />
            Fiyat Endeksi
          </h1>
          <p className="mx-auto mb-8 max-w-xl text-lg leading-relaxed text-muted">
            Yeedoy, Türkiye genelindeki restoran menü fiyatlarını topluluk doğrulamasıyla
            izleyen ülkenin ilk bağımsız fiyat endeksidir. Aylık yayınlanır — medya ve
            araştırmacılar için ücretsiz alıntılanabilir.
          </p>
          <div className="flex flex-wrap items-center justify-center gap-3">
            <Link
              href="#endeks"
              className="inline-flex min-h-[52px] items-center rounded-2xl px-6 text-sm font-black text-white shadow-(--yd-shadow-primary) transition-all hover:-translate-y-px hover:brightness-105"
              style={{ background: 'var(--yd-gradient-primary)' }}
            >
              Endeksi Gör
            </Link>
            <a
              href="mailto:veri@yeedoy.com"
              className="inline-flex min-h-[52px] items-center rounded-2xl border border-border bg-card px-6 text-sm font-black text-textStrong transition-colors hover:border-primary/35"
            >
              Medya İletişimi
            </a>
          </div>
        </Container>
      </section>

      {/* ── Özet istatistikler ────────────────────────────────────────────── */}
      <section className="border-b border-border">
        <Container className="py-10">
          <div className="grid gap-4 sm:grid-cols-3">
            {hasData ? (
              <>
                <StatCard
                  label="Doğrulanmış Fiyat Noktası"
                  value={totalSamples.toLocaleString('tr-TR')}
                  sub="menü kalemi"
                />
                <StatCard
                  label="30 Günde Güncellenen"
                  value={totalUpdated.toLocaleString('tr-TR')}
                  sub="aktif fiyat kaydı"
                />
                <StatCard
                  label="Kategori"
                  value={rows.length.toString()}
                  sub="yeterli örnekli"
                />
              </>
            ) : (
              <>
                <StatCard label="Doğrulanmış Fiyat Noktası" value="—" sub="Pilot çalışma devam ediyor" />
                <StatCard label="30 Günde Güncellenen" value="—" sub="Pilot çalışma devam ediyor" />
                <StatCard label="Kategori" value="—" sub="Pilot çalışma devam ediyor" />
              </>
            )}
          </div>
          <p className="mt-4 text-right text-xs text-muted">Son güncelleme: {ay}</p>
        </Container>
      </section>

      {/* ── Neden Şimdi? ──────────────────────────────────────────────────── */}
      <section className="border-b border-border">
        <Container className="py-14">
          <SectionHeader
            eyebrow="Bağlam"
            title="Neden Şimdi?"
            subtitle="Türkiye'de gıda enflasyonu son 67 aydır kesintisiz yükselirken tüketiciler güvenilir fiyat verilerinden yoksun kaldı."
            className="mb-8"
          />
          <div className="grid gap-5 sm:grid-cols-3">
            {WHY_NOW_CARDS.map((card) => (
              <div key={card.title} className="rounded-2xl border border-border bg-card p-6">
                <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-cardAlt text-primary">
                  {card.icon}
                </div>
                <p className="mb-1 text-[10px] font-extrabold uppercase tracking-widest text-muted">
                  {card.eyebrow}
                </p>
                <p className="mb-2 text-base font-black text-textStrong">{card.title}</p>
                <p className="text-sm leading-relaxed text-muted">{card.body}</p>
              </div>
            ))}
          </div>
        </Container>
      </section>

      {/* ── Veri Nasıl Toplanır? ─────────────────────────────────────────── */}
      <section className="border-b border-border bg-card">
        <Container className="py-14">
          <SectionHeader
            eyebrow="Metodoloji"
            title="Veri Nasıl Toplanır?"
            subtitle="Üç aşamalı süreç: işletme güncellemesi, topluluk doğrulaması ve güven skoru hesaplama."
            className="mb-10"
          />
          <div className="grid gap-5 sm:grid-cols-3">
            {HOW_STEPS.map((s) => (
              <div key={s.step} className="relative rounded-2xl border border-border bg-bg p-6">
                <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-2xl bg-primary/10 text-lg font-black text-primary">
                  {s.step}
                </div>
                <p className="mb-2 font-black text-textStrong">{s.title}</p>
                <p className="text-sm leading-relaxed text-muted">{s.body}</p>
              </div>
            ))}
          </div>
        </Container>
      </section>

      {/* ── Canlı Fiyat Endeksi Tablosu ──────────────────────────────────── */}
      <section id="endeks" className="border-b border-border">
        <Container className="py-14">
          <div className="mb-8 flex flex-wrap items-end justify-between gap-4">
            <div>
              <SectionHeader
                eyebrow="Canlı Veri"
                title="Kategoriye Göre Medyan Fiyat"
                subtitle="Minimum 3 doğrulanmış örneğe sahip kategoriler listelenmektedir."
              />
            </div>
            <a
              href="/sunucu/fiyat-endeksi-raporu"
              download
              className="inline-flex min-h-11 shrink-0 items-center gap-2 rounded-xl border border-border bg-card px-4 py-2.5 text-sm font-bold text-textStrong transition-colors hover:bg-cardAlt"
            >
              <svg
                width="15"
                height="15"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="7 10 12 15 17 10" />
                <line x1="12" y1="15" x2="12" y2="3" />
              </svg>
              CSV İndir
            </a>
          </div>

          {hasData ? (
            <div className="overflow-x-auto rounded-2xl border border-border bg-card">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3.5 text-[11px] font-extrabold uppercase tracking-wide text-muted">
                      Kategori
                    </th>
                    <th className="px-5 py-3.5 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">
                      Medyan
                    </th>
                    <th className="px-5 py-3.5 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">
                      Ortalama
                    </th>
                    <th className="px-5 py-3.5 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">
                      Örnek
                    </th>
                    <th className="px-5 py-3.5 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">
                      30 Gün
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {rows.map((row) => (
                    <tr key={row.category} className="transition-colors hover:bg-cardAlt/50">
                      <td className="px-5 py-3.5 font-bold text-textStrong">{row.category}</td>
                      <td className="px-5 py-3.5 text-right font-black text-textStrong">
                        {formatTL(row.median_price_cents)}
                      </td>
                      <td className="px-5 py-3.5 text-right text-muted">
                        {formatTL(row.avg_price_cents)}
                      </td>
                      <td className="px-5 py-3.5 text-right text-muted">
                        {row.sample_count.toLocaleString('tr-TR')}
                      </td>
                      <td className="px-5 py-3.5 text-right">
                        <span
                          className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${
                            row.updated_in_30d > 0
                              ? 'bg-success/10 text-success'
                              : 'bg-cardAlt text-muted'
                          }`}
                        >
                          {row.updated_in_30d}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="rounded-2xl border border-border bg-card p-10 text-center">
              <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-cardAlt text-muted">
                <svg
                  viewBox="0 0 40 40"
                  className="h-8 w-8"
                  aria-hidden="true"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                >
                  <circle cx="20" cy="20" r="14" />
                  <path d="M14 20 h12 M20 14 v12" opacity="0.4" />
                </svg>
              </div>
              <p className="text-lg font-black text-textStrong">Veri biriktirilıyor</p>
              <p className="mx-auto mt-2 max-w-sm text-sm leading-relaxed text-muted">
                Pilot çalışma devam ediyor. Yeedoy topluluğu menü fiyatlarını doğruladıkça bu
                endeks güncellenecek.{' '}
                <Link href="/kesif" className="font-bold text-primary hover:underline">
                  Bir işletme ziyaret et
                </Link>{' '}
                ve katkı sağla.
              </p>
              <div className="mt-6">
                <Badge tone="warning">Pilot Çalışma — Haziran 2026</Badge>
              </div>
            </div>
          )}

          <p className="mt-4 text-xs text-muted">
            Metodoloji: Minimum 3 doğrulanmış örneğe ulaşmayan kategoriler bu listede yer almaz.
            Medyan değer, fiyat aykırılıklarının etkisini azaltmak için ortalamaya tercih edilir.
          </p>
        </Container>
      </section>

      {/* ── Fiyat Seviyeleri ──────────────────────────────────────────────── */}
      <section className="border-b border-border bg-card">
        <Container className="py-14">
          <SectionHeader
            eyebrow="Sınıflandırma"
            title="Fiyat Seviyeleri"
            subtitle="Yeedoy'da her işletme ortalama masa tutarına göre üç fiyat segmentine ayrılmaktadır."
            className="mb-8"
          />
          <div className="grid gap-5 sm:grid-cols-3">
            {PRICE_LEVELS.map((pl) => (
              <div key={pl.symbol} className="rounded-2xl border border-border bg-bg p-6">
                <p className="mb-2 text-2xl font-black text-primary">{pl.symbol}</p>
                <p className="mb-2 font-black text-textStrong">{pl.label}</p>
                <p className="text-sm leading-relaxed text-muted">{pl.desc}</p>
              </div>
            ))}
          </div>
          <p className="mt-5 text-xs text-muted">
            Not: Fiyat seviyeleri topluluk bildirimleri ve doğrulanmış ziyaret verileri
            kullanılarak hesaplanmaktadır. TL değerleri enflasyon nedeniyle periyodik olarak
            güncellenmektedir.
          </p>
        </Container>
      </section>

      {/* ── 5 Veri Hikayesi ───────────────────────────────────────────────── */}
      <section className="border-b border-border">
        <Container className="py-14">
          <SectionHeader
            eyebrow="Veri Hikayeleri"
            title="Medya İçin Hazır 5 Veri Hikayesi"
            subtitle="Bu hikayeler Yeedoy veritabanından türetilebilecek analizleri yansıtmaktadır. Pilot çalışma kapsamında veri toplandıkça güncellenecektir."
            className="mb-8"
          />
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {DATA_STORIES.map((story, i) => (
              <div
                key={i}
                className="flex flex-col rounded-2xl border border-border bg-card p-6"
              >
                <div className="mb-3 flex items-start justify-between gap-3">
                  <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-sm font-black text-primary">
                    {i + 1}
                  </span>
                  <Badge tone="warning">Pilot Çalışma</Badge>
                </div>
                <p className="mb-2 font-black leading-snug text-textStrong">{story.title}</p>
                <p className="flex-1 text-sm leading-relaxed text-muted">{story.body}</p>
                <p className="mt-4 text-[10px] font-extrabold uppercase tracking-wide text-muted">
                  {story.score}
                </p>
              </div>
            ))}

            {/* Altıncı kart — metodoloji linki */}
            <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-border p-6 text-center">
              <p className="mb-2 font-black text-textStrong">Daha fazla veri hikayesi</p>
              <p className="mb-4 text-sm text-muted">
                Araştırmacı veya muhabirseniz ham veri ve metodoloji belgelerine erişim için
                bize ulaşın.
              </p>
              <a
                href="mailto:veri@yeedoy.com"
                className="inline-flex min-h-11 items-center rounded-2xl border border-border bg-card px-4 text-sm font-black text-textStrong transition-colors hover:border-primary/35"
              >
                veri@yeedoy.com
              </a>
            </div>
          </div>
        </Container>
      </section>

      {/* ── 3 CTA Bloğu ──────────────────────────────────────────────────── */}
      <section className="border-b border-border bg-card">
        <Container className="py-14">
          <SectionHeader
            eyebrow="İletişim"
            title="Sizi Dinliyoruz"
            className="mb-8"
          />
          <div className="grid gap-5 sm:grid-cols-3">
            {CTA_BLOCKS.map((block) => (
              <div
                key={block.eyebrow}
                className="flex flex-col rounded-2xl border border-border bg-bg p-6"
              >
                <p className="mb-1 text-[10px] font-extrabold uppercase tracking-widest text-muted">
                  {block.eyebrow}
                </p>
                <p className="mb-2 text-base font-black text-textStrong">{block.title}</p>
                <p className="mb-5 flex-1 text-sm leading-relaxed text-muted">{block.body}</p>
                {block.ctaVariant === 'mail' ? (
                  <a
                    href={block.ctaHref}
                    className="inline-flex min-h-11 items-center rounded-2xl border border-primary/25 bg-primary/10 px-4 text-sm font-black text-primary transition-colors hover:bg-primary/15"
                  >
                    {block.cta}
                  </a>
                ) : (
                  <Link
                    href={block.ctaHref}
                    className="inline-flex min-h-11 items-center rounded-2xl border border-border bg-card px-4 text-sm font-black text-textStrong transition-colors hover:border-primary/35"
                  >
                    {block.cta} →
                  </Link>
                )}
              </div>
            ))}
          </div>
        </Container>
      </section>

      {/* ── Metodoloji Notu ───────────────────────────────────────────────── */}
      <section>
        <Container className="py-14">
          <SectionHeader
            eyebrow="Şeffaflık"
            title="Metodoloji Notu"
            className="mb-6"
          />
          <div className="rounded-2xl border border-border bg-card p-7">
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              <MetaBlock
                title="Veri Kaynağı"
                body="İşletme sahibi güncellemeleri + topluluk fiyat bildirimleri. Tüm analizler aggregate düzeyde; bireysel kullanıcı veya işletme hedeflenmez."
              />
              <MetaBlock
                title="Hesaplama"
                body="Her kategori için medyan fiyat tercih edilir. Minimum örnek büyüklüğü: 3 doğrulanmış kayıt. Aykırı değerler (%5 alt–üst dilim) hariç tutulur."
              />
              <MetaBlock
                title="Güncelleme"
                body="Sayfa saatte bir yenilenir (ISR). Endeks veritabanı günlük olarak hesaplanır. Aylık rapor her ayın ilk haftasında yayınlanır."
              />
              <MetaBlock
                title="KVKK Uyumu"
                body="Tüm veriler anonim aggregate niteliktedir. Kişisel veri işleme kapsamı dışındadır. Gizlilik politikası için bkz. /gizlilik."
              />
            </div>
          </div>
          <p className="mt-4 text-center text-xs text-muted">
            Yeedoy Türkiye Restoran Fiyat Endeksi — Haziran 2026 Pilot Raporu ·{' '}
            <a href="mailto:veri@yeedoy.com" className="font-bold text-primary hover:underline">
              veri@yeedoy.com
            </a>
          </p>
        </Container>
      </section>
    </PublicShell>
  );
}

// ── Alt bileşenler ────────────────────────────────────────────────────────────

function StatCard({ label, value, sub }: { label: string; value: string; sub: string }) {
  return (
    <div className="rounded-2xl border border-border bg-card p-5">
      <p className="text-[11px] font-extrabold uppercase tracking-wide text-muted">{label}</p>
      <p className="mt-1 text-3xl font-black text-textStrong">{value}</p>
      <p className="text-xs text-muted">{sub}</p>
    </div>
  );
}

function MetaBlock({ title, body }: { title: string; body: string }) {
  return (
    <div>
      <p className="mb-1.5 text-sm font-black text-textStrong">{title}</p>
      <p className="text-sm leading-relaxed text-muted">{body}</p>
    </div>
  );
}
