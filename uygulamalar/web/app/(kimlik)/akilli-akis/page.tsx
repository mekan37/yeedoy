import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { AppSectionHeader } from '@/src/ui/bilesenler/uygulama-bolum-basligi';
import { BusinessTile } from '@/src/ui/bilesenler/isletme-karti';

export const metadata: Metadata = {
  title: 'Akıllı Besleme | Yeedoy',
  robots: { index: false, follow: false },
};

type BizRow = {
  id: string; name: string; slug: string; category: string | null;
  city: string | null; logo_url: string | null; is_verified: boolean;
};

type BehaviorSegment = {
  primary_segment: 'price_hunter' | 'discovery_seeker' | 'photo_hunter' | 'balanced';
  price_actions: number;
  discovery_actions: number;
  photo_actions: number;
};

type DietProfile = {
  is_vegan: boolean; is_vegetarian: boolean; is_gluten_free: boolean;
  is_lactose_free: boolean; is_halal: boolean; max_calories: number | null;
};

const SEGMENT_META: Record<BehaviorSegment['primary_segment'], { title: string; description: string; icon: string; color: string }> = {
  price_hunter: {
    title: 'Fiyat Avcısı',
    description: 'Uygun fiyatlı ve kaliteli seçeneklere yönlendiriliyorsun.',
    icon: 'tag',
    color: 'text-amber-600 bg-amber-50 border-amber-200',
  },
  discovery_seeker: {
    title: 'Keşifçi',
    description: 'Yeni mekanlar ve deneyimler peşindesin.',
    icon: 'compass',
    color: 'text-blue-600 bg-blue-50 border-blue-200',
  },
  photo_hunter: {
    title: 'Görsel Gurme',
    description: 'Fotoğrafları iyi işletmelere ilgi duyuyorsun.',
    icon: 'camera',
    color: 'text-purple-600 bg-purple-50 border-purple-200',
  },
  balanced: {
    title: 'Dengeli Gurme',
    description: 'Geniş bir yelpazede keşfediyorsun.',
    icon: 'sparkle',
    color: 'text-primary bg-[var(--yd-color-primary-soft)] border-primary/20',
  },
};

function dietLabel(diet: DietProfile): string[] {
  const labels: string[] = [];
  if (diet.is_vegan) labels.push('Vegan');
  if (diet.is_vegetarian && !diet.is_vegan) labels.push('Vejetaryen');
  if (diet.is_gluten_free) labels.push('Glutensiz');
  if (diet.is_lactose_free) labels.push('Laktozsuz');
  if (diet.is_halal) labels.push('Helal');
  return labels;
}

export default async function SmartFeedPage() {
  const supabase = await createSupabaseServerClient();

  const [segmentRes, dietRes] = await Promise.all([
    (supabase as any).rpc('get_my_behavior_segment_v1') as Promise<{ data: BehaviorSegment | null }>,
    (supabase as any).rpc('get_my_diet_profile_v1') as Promise<{ data: DietProfile | null }>,
  ]);

  const segment = segmentRes.data;
  const diet = dietRes.data;
  const dietLabels = diet ? dietLabel(diet) : [];
  const segmentKey = segment?.primary_segment ?? 'balanced';
  const meta = SEGMENT_META[segmentKey];

  // Build category filter from diet + segment
  const categoryHints: string[] = [];
  if (segmentKey === 'price_hunter') categoryHints.push('Fast Food', 'Dönerci', 'Pide / Lahmacun');
  if (segmentKey === 'discovery_seeker') categoryHints.push('Restoran', 'Kafe', 'Balık');
  if (segmentKey === 'balanced' || segmentKey === 'photo_hunter') categoryHints.push('Restoran', 'Kafe');

  // Fetch personalized recs — 2 batches: one for segment-matching category, one for verified
  let primaryRecs: BizRow[] = [];
  let verifiedRecs: BizRow[] = [];
  try {
    const [p, v] = await Promise.all([
      categoryHints.length > 0
        ? (supabase as any)
            .from('businesses')
            .select('id, name, slug, category, city, logo_url, is_verified')
            .eq('is_active', true)
            .in('category', categoryHints)
            .order('created_at', { ascending: false })
            .limit(8) as Promise<{ data: BizRow[] | null }>
        : Promise.resolve({ data: [] as BizRow[] }),
      (supabase as any)
        .from('businesses')
        .select('id, name, slug, category, city, logo_url, is_verified')
        .eq('is_active', true)
        .eq('is_verified', true)
        .order('created_at', { ascending: false })
        .limit(6) as Promise<{ data: BizRow[] | null }>,
    ]);
    primaryRecs = p.data ?? [];
    verifiedRecs = (v.data ?? []).filter((b) => !primaryRecs.some((p) => p.id === b.id)).slice(0, 6);
  } catch { /* graceful fallback */ }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 pb-20 pt-10">

        {/* Back */}
        <Link href="/profil"
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted transition-colors hover:text-primary">
          <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current" aria-hidden="true"><path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/></svg>
          Profile Dön
        </Link>

        <h1 className="mb-1 text-2xl font-[900] text-textStrong">Akıllı Besleme</h1>
        <p className="mb-6 text-sm text-muted">Davranışlarına ve tercihlerine göre özelleştirilmiş öneriler</p>

        {/* Segment card */}
        <div className={`mb-6 flex items-start gap-4 rounded-[20px] border p-4 ${meta.color}`}>
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border bg-white/60 backdrop-blur">
            <SegmentIcon type={meta.icon} />
          </div>
          <div className="min-w-0 flex-1">
            <p className="font-[900]">{meta.title}</p>
            <p className="mt-0.5 text-sm opacity-80">{meta.description}</p>
            {segment && (segment.price_actions + segment.discovery_actions + segment.photo_actions) > 0 && (
              <div className="mt-2 flex flex-wrap gap-3 text-[11px] font-[800] opacity-70">
                {segment.price_actions > 0 && <span>Fiyat: {segment.price_actions}</span>}
                {segment.discovery_actions > 0 && <span>Keşif: {segment.discovery_actions}</span>}
                {segment.photo_actions > 0 && <span>Fotoğraf: {segment.photo_actions}</span>}
              </div>
            )}
          </div>
        </div>

        {/* Diet preferences */}
        {dietLabels.length > 0 && (
          <div className="mb-6 flex flex-wrap items-center gap-2 rounded-[20px] border border-border bg-cardAlt px-4 py-3 shadow-yd1">
            <span className="text-xs font-[900] text-muted uppercase tracking-wide">Diyet:</span>
            {dietLabels.map((label) => (
              <span key={label} className="rounded-full border border-success/25 bg-success/[0.12] px-2.5 py-0.5 text-xs font-[800] text-success">
                {label}
              </span>
            ))}
            <Link href="/baslangic" className="ml-auto text-xs font-[700] text-primary hover:underline">
              Güncelle →
            </Link>
          </div>
        )}

        {/* Primary recommendations */}
        {primaryRecs.length > 0 && (
          <section className="mb-8">
            <AppSectionHeader
              title={`${meta.title} Önerileri`}
              subtitle={`${segmentKey === 'price_hunter' ? 'Uygun fiyatlı' : segmentKey === 'discovery_seeker' ? 'Keşfedilmemiş' : 'Seçilmiş'} mekanlar`}
              className="mb-4"
            />
            <div className="flex flex-col gap-3">
              {primaryRecs.map((biz) => (
                <BusinessTile key={biz.id} slug={biz.slug} name={biz.name}
                  category={biz.category ?? undefined} subtitle={biz.city ?? undefined}
                  isVerified={biz.is_verified} />
              ))}
            </div>
          </section>
        )}

        {/* Verified picks */}
        {verifiedRecs.length > 0 && (
          <section className="mb-8">
            <AppSectionHeader title="Doğrulanmış Seçmeler"
              subtitle="Yeedoy tarafından doğrulanmış işletmeler"
              className="mb-4"
            />
            <div className="flex flex-col gap-3">
              {verifiedRecs.map((biz) => (
                <BusinessTile key={biz.id} slug={biz.slug} name={biz.name}
                  category={biz.category ?? undefined} subtitle={biz.city ?? undefined}
                  isVerified={biz.is_verified} />
              ))}
            </div>
          </section>
        )}

        {primaryRecs.length === 0 && verifiedRecs.length === 0 && (
          <div className="rounded-[20px] border border-border bg-card p-10 text-center">
            <p className="font-[900] text-textStrong">Henüz öneri yok</p>
            <p className="mt-2 text-sm text-muted">Daha fazla işletme keşfettikçe kişisel öneriler burada görünecek.</p>
            <Link href="/kesif"
              className="mt-4 inline-flex min-h-[44px] items-center rounded-2xl px-5 text-sm font-[800] text-white transition-all hover:-translate-y-px hover:brightness-105 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
              Keşfetmeye Başla
            </Link>
          </div>
        )}

        {/* Quick links */}
        <div className="mt-4 grid grid-cols-2 gap-3">
          {[
            { href: '/tat-ikizi', label: 'Taste Twin', desc: 'Zevk eşleri' },
            { href: '/fiyat-uyarilari', label: 'Fiyat Alarmları', desc: 'Takip et' },
          ].map(({ href, label, desc }) => (
            <Link key={href} href={href}
              className="flex flex-col gap-0.5 rounded-[20px] border border-border bg-cardAlt p-4 shadow-yd1 transition-all hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-yd2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
              <span className="font-[800] text-textStrong">{label}</span>
              <span className="text-xs text-muted">{desc}</span>
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}

function SegmentIcon({ type }: { type: string }) {
  if (type === 'tag') return (
    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/>
    </svg>
  );
  if (type === 'compass') return (
    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/>
    </svg>
  );
  if (type === 'camera') return (
    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/>
    </svg>
  );
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
    </svg>
  );
}


