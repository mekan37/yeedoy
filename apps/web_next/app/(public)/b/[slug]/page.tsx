import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { appConfig } from '@/src/lib/config';
import { AppSectionHeader } from '@/src/ui/components/app-section-header';
import { buildMenuImageUrl } from '@/src/lib/media-url';

export const revalidate = 120;

type Props = { params: Promise<{ slug: string }> };

type Business = {
  id: string; name: string; slug: string; description: string | null;
  logo_url: string | null; cover_url: string | null;
  category: string | null; city: string | null; district: string | null;
  address: string | null; phone: string | null; website: string | null;
  whatsapp_number: string | null; instagram_handle: string | null;
  facebook_page: string | null; lat: number | null; lng: number | null;
  is_verified: boolean; is_active: boolean;
};

type Hours = {
  mon_open: string | null; mon_close: string | null;
  tue_open: string | null; tue_close: string | null;
  wed_open: string | null; wed_close: string | null;
  thu_open: string | null; thu_close: string | null;
  fri_open: string | null; fri_close: string | null;
  sat_open: string | null; sat_close: string | null;
  sun_open: string | null; sun_close: string | null;
} | null;

type Review = {
  id: string; rating: number; body: string | null; content: string | null;
  created_at: string; verified_visit?: boolean;
  user_profiles: { display_name: string | null } | null;
};

type MenuRow = { id: string; title: string; slug: string | null; status: string };

const DAY_KEYS = ['sun','mon','tue','wed','thu','fri','sat'] as const;
const DAY_LABELS = ['Pazar','Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi'];

function isOpenNow(hours: Hours): { open: boolean; closeAt: string | null } {
  if (!hours) return { open: false, closeAt: null };
  const now = new Date();
  const day = DAY_KEYS[now.getDay()];
  const openStr = hours[`${day}_open` as keyof Hours] as string | null;
  const closeStr = hours[`${day}_close` as keyof Hours] as string | null;
  if (!openStr || !closeStr) return { open: false, closeAt: null };
  const [oh, om] = openStr.split(':').map(Number);
  const [ch, cm] = closeStr.split(':').map(Number);
  const nowMins = now.getHours() * 60 + now.getMinutes();
  const openMins = oh * 60 + om;
  const closeMins = ch * 60 + cm;
  const open = nowMins >= openMins && nowMins < closeMins;
  return { open, closeAt: closeStr.slice(0, 5) };
}

function fmtTime(t: string | null) {
  if (!t) return '—';
  return t.slice(0, 5);
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any)
    .from('businesses').select('name, description, city, category').eq('slug', slug).single() as
    { data: Pick<Business,'name'|'description'|'city'|'category'> | null };
  if (!data) return { title: 'İşletme | Yeedoy' };
  const title = `${data.name}${data.city ? ` — ${data.city}` : ''} | Yeedoy`;
  return {
    title,
    description: data.description ?? `${data.name} menüsünü görüntüle ve yorum yap`,
    openGraph: { title },
  };
}

export default async function BusinessPage({ params }: Props) {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();

  const { data: biz } = await (supabase as any)
    .from('businesses')
    .select('id, name, slug, description, logo_url, cover_url, category, city, district, address, phone, website, whatsapp_number, instagram_handle, facebook_page, lat, lng, is_verified, is_active')
    .eq('slug', slug).single() as { data: Business | null };

  if (!biz || !biz.is_active) notFound();

  const [menusRes, reviewsRes, statsRes, hoursRes, photosRes] = await Promise.all([
    (supabase as any).from('menus').select('id, title, slug, status').eq('business_id', biz.id).eq('status', 'published').order('created_at', { ascending: true }).limit(10) as Promise<{ data: MenuRow[] | null }>,
    (supabase as any).from('business_reviews').select('id, rating, body, content, created_at, verified_visit, user_profiles!user_id(display_name)').eq('business_id', biz.id).eq('is_visible', true).order('created_at', { ascending: false }).limit(5) as Promise<{ data: Review[] | null }>,
    (supabase as any).from('business_reviews').select('rating', { count: 'exact' }).eq('business_id', biz.id).eq('is_visible', true) as Promise<{ data: { rating: number }[] | null; count: number | null }>,
    (supabase as any).from('business_hours').select('*').eq('business_id', biz.id).maybeSingle() as Promise<{ data: Hours }>,
    (supabase as any).from('menu_item_photos').select('url, url_thumb').eq('business_id', biz.id).eq('status', 'approved').eq('is_hidden', false).order('up_votes', { ascending: false }).limit(9) as Promise<{ data: Array<{ url: string; url_thumb: string | null }> | null }>,
  ]);

  const menus = menusRes.data ?? [];
  const reviews = reviewsRes.data ?? [];
  const reviewCount = statsRes.count ?? 0;
  const ratings = statsRes.data ?? [];
  const avgRating = ratings.length > 0 ? ratings.reduce((s, r) => s + r.rating, 0) / ratings.length : null;
  const hours = hoursRes.data;
  const photos = photosRes.data ?? [];
  const { open: isOpen, closeAt } = isOpenNow(hours);

  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const hasContact = biz.phone || biz.whatsapp_number || biz.website || biz.instagram_handle || biz.address || (biz.lat && biz.lng);

  return (
    <main className="min-h-screen bg-bg">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify({
        '@context': 'https://schema.org', '@type': 'Restaurant', name: biz.name,
        ...(biz.description ? { description: biz.description } : {}),
        address: { '@type': 'PostalAddress', ...(biz.city ? { addressLocality: biz.city } : {}), addressCountry: 'TR' },
        ...(biz.phone ? { telephone: biz.phone } : {}),
        url: `${siteUrl}/b/${biz.slug}`,
        ...(biz.category ? { servesCuisine: biz.category } : {}),
        ...(biz.logo_url ? { image: biz.logo_url } : {}),
        ...(avgRating !== null ? { aggregateRating: { '@type': 'AggregateRating', ratingValue: avgRating.toFixed(1), reviewCount } } : {}),
      }) }} />

      {/* ── Hero ─────────────────────────────────────────────────────────── */}
      <div className="relative overflow-hidden" style={{ minHeight: 220 }}>
        {biz.cover_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={buildMenuImageUrl(biz.cover_url, { width: 1200 }) ?? biz.cover_url ?? ''} alt={biz.name} className="absolute inset-0 h-full w-full object-cover" />
        ) : (
          <div className="absolute inset-0" style={{ background: 'linear-gradient(135deg, #5c1515 0%, #7f1d1d 40%, #dc2626 100%)' }} />
        )}
        {/* Gradient overlay */}
        <div className="absolute inset-0" style={{ background: 'linear-gradient(to bottom, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.7) 100%)' }} />

        {/* Hero content */}
        <div className="relative mx-auto max-w-3xl px-4 pb-8 pt-14 sm:px-8 sm:pt-20">
          <div className="flex items-end gap-4">
            {/* Logo */}
            <div className="h-20 w-20 shrink-0 overflow-hidden rounded-[18px] border-2 border-white/30 bg-white/10 backdrop-blur shadow-yd3 sm:h-24 sm:w-24">
              {biz.logo_url ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={biz.logo_url} alt={biz.name} className="h-full w-full object-cover" />
              ) : (
                <div className="flex h-full w-full items-center justify-center text-3xl font-[900] text-white">
                  {biz.name[0]}
                </div>
              )}
            </div>

            <div className="min-w-0 flex-1 pb-1">
              {/* Verified + open badges */}
              <div className="mb-2 flex flex-wrap items-center gap-2">
                {biz.is_verified && (
                  <span className="inline-flex items-center gap-1 rounded-full bg-green-500/90 px-2.5 py-0.5 text-[11px] font-[800] text-white backdrop-blur">
                    <svg viewBox="0 0 24 24" className="h-3 w-3 fill-current"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
                    Doğrulanmış
                  </span>
                )}
                {hours && (
                  <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${isOpen ? 'bg-green-500/90 text-white' : 'bg-black/50 text-white/80'}`}>
                    {isOpen ? `Açık · ${closeAt}'e kadar` : 'Şu an kapalı'}
                  </span>
                )}
              </div>

              <h1 className="font-display text-2xl font-[900] leading-tight text-white sm:text-3xl">{biz.name}</h1>

              <div className="mt-1.5 flex flex-wrap items-center gap-2 text-white/80">
                {biz.category && <span className="text-sm">{biz.category}</span>}
                {biz.city && <><span className="text-white/40">·</span><span className="text-sm">{biz.district ? `${biz.district}, ${biz.city}` : biz.city}</span></>}
                {avgRating !== null && (
                  <><span className="text-white/40">·</span>
                  <span className="flex items-center gap-1 text-sm font-[800] text-amber-400">
                    <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-current"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                    {avgRating.toFixed(1)}
                    <span className="font-[400] text-white/60">({reviewCount})</span>
                  </span></>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ── Body ─────────────────────────────────────────────────────────── */}
      <div className="mx-auto max-w-3xl px-4 pb-20 pt-6 sm:px-8">

        {/* CTA row */}
        <div className="mb-8 flex flex-wrap items-center gap-3">
          {menus.length > 0 && (
            <Link href={`/m/${menus[0].slug ?? menus[0].id}`}
              className="inline-flex min-h-[44px] items-center gap-2 rounded-2xl px-5 text-sm font-[800] text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
              <MenuBookIcon /> Menüyü Gör
            </Link>
          )}
          <Link href={`/b/${biz.slug}/reviews/new`}
            className="inline-flex min-h-[44px] items-center gap-2 rounded-2xl border border-border bg-card px-5 text-sm font-[800] text-textStrong transition-colors hover:border-primary/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
            <StarIcon /> Yorum Yaz
          </Link>
          <Link href={`/b/${biz.slug}/reviews`}
            className="inline-flex min-h-[44px] items-center gap-1.5 rounded-2xl border border-border bg-card px-4 text-sm font-[700] text-muted transition-colors hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
            Tüm yorumlar →
          </Link>
        </div>

        {/* Description */}
        {biz.description && (
          <p className="mb-8 text-sm leading-relaxed text-muted">{biz.description}</p>
        )}

        {/* ── Two columns on md+ ───────────────────────────────────────── */}
        <div className="grid gap-6 md:grid-cols-[1fr_280px]">
          <div className="space-y-8 min-w-0">

            {/* Photos gallery */}
            {photos.length > 0 && (
              <section>
                <AppSectionHeader title="Fotoğraflar" className="mb-4" />
                <div className="grid grid-cols-3 gap-2">
                  {photos.slice(0, 9).map((p, i) => (
                    <div key={i} className="aspect-square overflow-hidden rounded-xl bg-border">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={buildMenuImageUrl(p.url_thumb ?? p.url, { width: 300 }) ?? p.url_thumb ?? p.url} alt="" className="h-full w-full object-cover transition-transform duration-300 hover:scale-105" loading="lazy" />
                    </div>
                  ))}
                </div>
              </section>
            )}

            {/* Menus */}
            {menus.length > 0 && (
              <section>
                <AppSectionHeader title="Menüler" className="mb-4" />
                <div className="flex flex-col gap-2">
                  {menus.map((m) => (
                    <Link key={m.id} href={`/m/${m.slug ?? m.id}`}
                      className="flex items-center justify-between rounded-[20px] border border-border bg-cardAlt px-5 py-4 shadow-yd1 transition-all hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-yd2 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                      <div className="flex items-center gap-3">
                        <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted">
                          <MenuBookIcon size={16} />
                        </span>
                        <span className="font-[800] text-textStrong">{m.title}</span>
                      </div>
                      <span className="text-sm font-[700] text-primary">Görüntüle →</span>
                    </Link>
                  ))}
                </div>
              </section>
            )}

            {/* Reviews */}
            <section>
              <div className="mb-4 flex items-center justify-between">
                <AppSectionHeader title={`Yorumlar${reviewCount > 0 ? ` (${reviewCount})` : ''}`} />
                {reviewCount > 5 && (
                  <Link href={`/b/${biz.slug}/reviews`} className="text-sm font-[700] text-primary hover:underline">Tümünü gör →</Link>
                )}
              </div>
              {reviews.length === 0 ? (
                <div className="rounded-[20px] border border-border bg-card p-8 text-center">
                  <p className="text-muted mb-3">Henüz yorum yok.</p>
                  <Link href={`/b/${biz.slug}/reviews/new`} className="text-sm font-[700] text-primary hover:underline">İlk yorumu sen yaz →</Link>
                </div>
              ) : (
                <div className="flex flex-col gap-3">
                  {reviews.map((r) => {
                    const text = r.body ?? r.content;
                    const author = r.user_profiles?.display_name ?? 'Anonim Gurme';
                    return (
                      <article key={r.id} className="rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1">
                        <div className="flex items-start justify-between gap-2 mb-2">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="font-[800] text-textStrong text-sm">{author}</span>
                            {r.verified_visit && (
                              <span className="inline-flex items-center gap-1 rounded-full border border-success/25 bg-success/[0.12] px-2 py-0.5 text-[10px] font-[800] text-success">
                                <svg viewBox="0 0 24 24" className="h-2.5 w-2.5 fill-current"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
                                Doğrulanmış
                              </span>
                            )}
                          </div>
                          <div className="flex shrink-0 items-center gap-0.5">
                            {Array.from({ length: 5 }).map((_, i) => (
                              <svg key={i} width="11" height="11" viewBox="0 0 24 24" fill={i < r.rating ? '#f59e0b' : 'none'} stroke={i < r.rating ? '#f59e0b' : '#d1d5db'} strokeWidth="2">
                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                              </svg>
                            ))}
                          </div>
                        </div>
                        {text && <p className="text-sm text-textStrong leading-relaxed">&ldquo;{text}&rdquo;</p>}
                        <p className="mt-2 text-[11px] text-muted">
                          {new Date(r.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
                        </p>
                      </article>
                    );
                  })}
                </div>
              )}
            </section>
          </div>

          {/* ── Sidebar ────────────────────────────────────────────────── */}
          <aside className="space-y-4">

            {/* Hours card */}
            {hours && (
              <div className="rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1">
                <h3 className="mb-3 flex items-center gap-2 text-sm font-[900] text-textStrong">
                  <ClockIcon /> Çalışma Saatleri
                </h3>
                <ul className="space-y-1.5">
                  {DAY_KEYS.map((day, idx) => {
                    const openT = hours[`${day}_open` as keyof Hours] as string | null;
                    const closeT = hours[`${day}_close` as keyof Hours] as string | null;
                    const isToday = idx === new Date().getDay();
                    return (
                      <li key={day} className={`flex items-center justify-between text-xs ${isToday ? 'font-[800] text-textStrong' : 'text-muted'}`}>
                        <span>{DAY_LABELS[idx]}{isToday && ' (bugün)'}</span>
                        <span>{openT ? `${fmtTime(openT)} – ${fmtTime(closeT)}` : 'Kapalı'}</span>
                      </li>
                    );
                  })}
                </ul>
              </div>
            )}

            {/* Contact card */}
            {hasContact && (
              <div className="rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1">
                <h3 className="mb-3 flex items-center gap-2 text-sm font-[900] text-textStrong">
                  <ContactIcon /> İletişim
                </h3>
                <ul className="space-y-2.5">
                  {biz.phone && (
                    <li>
                      <a href={`tel:${biz.phone}`} className="flex items-center gap-2.5 text-sm text-textStrong hover:text-primary transition-colors">
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted"><PhoneIcon /></span>
                        {biz.phone}
                      </a>
                    </li>
                  )}
                  {(biz.whatsapp_number ?? biz.phone) && (
                    <li>
                      <a href={`https://wa.me/${(biz.whatsapp_number ?? biz.phone)?.replace(/\D/g,'')}`} target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-2.5 text-sm text-textStrong hover:text-green-600 transition-colors">
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted"><WhatsappIcon /></span>
                        WhatsApp
                      </a>
                    </li>
                  )}
                  {biz.lat && biz.lng && (
                    <li>
                      <a href={`https://maps.google.com/?q=${biz.lat},${biz.lng}`} target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-2.5 text-sm text-textStrong hover:text-primary transition-colors">
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted"><MapIcon /></span>
                        {biz.address ?? 'Haritada göster'}
                      </a>
                    </li>
                  )}
                  {!biz.lat && biz.address && (
                    <li>
                      <a href={`https://maps.google.com/?q=${encodeURIComponent(biz.address + ' ' + (biz.city ?? ''))}`} target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-2.5 text-sm text-textStrong hover:text-primary transition-colors">
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted"><MapIcon /></span>
                        {biz.address}
                      </a>
                    </li>
                  )}
                  {biz.instagram_handle && (
                    <li>
                      <a href={`https://instagram.com/${biz.instagram_handle}`} target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-2.5 text-sm text-textStrong hover:text-pink-600 transition-colors">
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted"><InstagramIcon /></span>
                        @{biz.instagram_handle}
                      </a>
                    </li>
                  )}
                  {biz.website && (
                    <li>
                      <a href={biz.website} target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-2.5 text-sm text-primary hover:underline transition-colors">
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl border border-border bg-bg text-muted"><GlobeIcon /></span>
                        Web sitesi
                      </a>
                    </li>
                  )}
                </ul>
              </div>
            )}

            {/* QR shortcut */}
            {menus.length > 0 && (
              <Link href={`/qr/${biz.id}`}
                className="flex items-center gap-3 rounded-[20px] border border-border bg-cardAlt p-4 shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[var(--yd-color-primary-soft)] text-primary">
                  <QrIcon />
                </span>
                <div>
                  <p className="text-sm font-[800] text-textStrong">QR Kodu</p>
                  <p className="text-xs text-muted">Mobilde tara</p>
                </div>
              </Link>
            )}
          </aside>
        </div>
      </div>
    </main>
  );
}

// ── Icons ─────────────────────────────────────────────────────────────────────
function MenuBookIcon({ size = 18 }: { size?: number }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>;
}
function StarIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>;
}
function ClockIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>;
}
function ContactIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>;
}
function PhoneIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 13a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.6 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L7.91 9.91a16 16 0 0 0 6 6l.92-1a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>;
}
function WhatsappIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>;
}
function MapIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>;
}
function InstagramIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/></svg>;
}
function GlobeIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>;
}
function QrIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h.01M14 17h.01M17 14h.01M17 17h.01M20 14h.01M20 17h.01M20 20h.01"/></svg>;
}
