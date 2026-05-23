import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { AppSectionHeader } from '@/src/ui/bilesenler/uygulama-bolum-basligi';

export const metadata: Metadata = {
  title: 'Gurme Akışı | Yeedoy',
  description: 'Yeedoy gurme topluluğunun son yorum ve katkıları',
  openGraph: { title: 'Gurme Akışı | Yeedoy', description: 'Topluluk gözdesinin son aktiviteleri' },
};

export const revalidate = 60;

type ReviewRow = {
  id: string; rating: number; body: string | null; content: string | null;
  created_at: string; verified_visit?: boolean;
  businesses: { name: string; slug: string } | null;
  user_profiles: { display_name: string | null; avatar_url: string | null } | null;
};

type PersonalRecBusiness = {
  id: string;
  name: string;
  slug: string;
  category?: string | null;
  city?: string | null;
  avg_rating?: number | null;
};

type PriceAlertRow = {
  id: string;
  menu_items: {
    name: string;
    price_cents: number;
    businesses: { name: string; slug: string } | null;
  } | null;
};

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins} dk önce`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} sa önce`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days} gün önce`;
  return new Date(dateStr).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' });
}

export default async function FeedPage() {
  const supabase = await createSupabaseServerClient();

  // Auth check
  const { data: { user } } = await supabase.auth.getUser().catch(() => ({ data: { user: null } }));

  // Community feed
  let reviews: ReviewRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('business_reviews')
      .select('id, rating, body, content, created_at, verified_visit, businesses!business_id(name, slug), user_profiles!user_id(display_name, avatar_url)')
      .eq('is_visible', true)
      .order('created_at', { ascending: false })
      .limit(30) as { data: ReviewRow[] | null; error: any };
    if (!error || error.code !== '42P01') reviews = data ?? [];
  } catch { reviews = []; }

  // Personalized recommendations (logged-in only)
  let personalRecs: PersonalRecBusiness[] = [];
  if (user) {
    // Try smart feed RPC first, fall back to favorites table
    try {
      const { data, error } = await (supabase as any)
        .rpc('get_smart_feed_v1', { p_limit: 6 }) as { data: any[] | null; error: any };
      if (!error && data && data.length > 0) {
        personalRecs = data.map((row: any) => ({
          id: row.id ?? row.business_id ?? '',
          name: row.name ?? '',
          slug: row.slug ?? '',
          category: row.category ?? null,
          city: row.city ?? null,
          avg_rating: typeof row.avg_rating === 'number' ? row.avg_rating : null,
        }));
      }
    } catch { /* fall through */ }

    if (personalRecs.length === 0) {
      try {
        const { data } = await (supabase as any)
          .from('favorites')
          .select('business_id, businesses!business_id(id, name, slug, category, city, avg_rating)')
          .eq('user_id', user.id)
          .order('created_at', { ascending: false })
          .limit(6) as { data: any[] | null };
        personalRecs = (data ?? []).map((row: any) => {
          const biz = row.businesses;
          return {
            id: biz?.id ?? '',
            name: biz?.name ?? '',
            slug: biz?.slug ?? '',
            category: biz?.category ?? null,
            city: biz?.city ?? null,
            avg_rating: typeof biz?.avg_rating === 'number' ? biz.avg_rating : null,
          };
        }).filter((b: PersonalRecBusiness) => b.id && b.slug);
      } catch { personalRecs = []; }
    }
  }

  // Price alerts (logged-in only)
  let priceAlerts: PriceAlertRow[] = [];
  if (user) {
    try {
      const { data } = await (supabase as any)
        .from('price_alerts')
        .select('id, menu_items!menu_item_id(name, price_cents, businesses!business_id(name, slug))')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .limit(4) as { data: PriceAlertRow[] | null };
      priceAlerts = data ?? [];
    } catch { priceAlerts = []; }
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 pb-16 pt-10">

        <AppSectionHeader
          title="Gurme Akışı"
          subtitle="Topluluğun son yorum ve değerlendirmeleri"
          className="mb-8"
        />

        {/* Logged-in personalized sections */}
        {user ? (
          <>
            {/* Senin İçin */}
            {personalRecs.length > 0 && (
              <section className="mb-8">
                <h2 className="mb-4 text-lg font-[900] text-textStrong">Senin İçin</h2>
                <div className="flex flex-col gap-3">
                  {personalRecs.map((biz) => (
                    <Link
                      key={biz.id}
                      href={`/isletme/${biz.slug}`}
                      className="flex items-center justify-between gap-3 rounded-[20px] border border-border bg-card px-4 py-3 shadow-yd1 transition-all hover:-translate-y-0.5 hover:border-primary/25 hover:shadow-yd2"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-sm font-[900] text-textStrong">{biz.name}</p>
                        {(biz.category || biz.city) && (
                          <p className="mt-0.5 truncate text-xs text-muted">
                            {[biz.category, biz.city].filter(Boolean).join(' · ')}
                          </p>
                        )}
                      </div>
                      {biz.avg_rating != null && (
                        <span className="shrink-0 inline-flex items-center gap-1 rounded-full border border-warning/25 bg-warning/[0.14] px-2 py-0.5 text-xs font-[900] text-textStrong">
                          ★ {biz.avg_rating.toFixed(1)}
                        </span>
                      )}
                    </Link>
                  ))}
                </div>
              </section>
            )}

            {/* Fiyat Alarmları */}
            {priceAlerts.length > 0 && (
              <section className="mb-8">
                <h2 className="mb-4 text-lg font-[900] text-textStrong">Fiyat Alarmlarım</h2>
                <div className="flex flex-col gap-3">
                  {priceAlerts.map((alert) => {
                    const item = alert.menu_items;
                    const biz = item?.businesses;
                    const priceTry = item?.price_cents
                      ? `₺${(item.price_cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`
                      : null;
                    return (
                      <div
                        key={alert.id}
                        className="flex items-center justify-between gap-3 rounded-[20px] border border-border bg-cardAlt px-4 py-3 shadow-yd1"
                      >
                        <div className="min-w-0">
                          <p className="truncate text-sm font-[900] text-textStrong">
                            {item?.name ?? 'Ürün'}
                          </p>
                          {biz && (
                            <Link
                              href={`/isletme/${biz.slug}`}
                              className="mt-0.5 block truncate text-xs text-primary hover:underline"
                            >
                              {biz.name}
                            </Link>
                          )}
                        </div>
                        {priceTry && (
                          <span className="shrink-0 text-sm font-[900] text-textStrong">
                            {priceTry}
                          </span>
                        )}
                      </div>
                    );
                  })}
                </div>
              </section>
            )}
          </>
        ) : (
          /* Anonymous callout */
          <div className="mb-8 rounded-[20px] border border-primary/20 bg-[var(--yd-color-primary-soft)] px-5 py-6">
            <p className="font-[900] text-textStrong">Kişisel akışını görüntüle</p>
            <p className="mt-2 text-sm leading-6 text-muted">
              Giriş yaparak favori işletmelerini, fiyat alarmlarını ve sana özel önerileri bu sayfada görüntüleyebilirsin.
            </p>
            <Link
              href="/giris"
              className="mt-4 inline-flex min-h-[44px] items-center justify-center rounded-2xl px-5 text-sm font-[900] text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{ background: 'var(--yd-gradient-primary)' }}
            >
              Giriş yap
            </Link>
          </div>
        )}

        {/* Community feed heading */}
        <h2 className="mb-4 text-lg font-[900] text-textStrong">Topluluk Akışı</h2>

        {reviews.length === 0 ? (
          <div className="rounded-[20px] border border-border bg-card p-10 text-center">
            <p className="font-[900] text-textStrong mb-2">Henüz aktivite yok</p>
            <Link href="/kesif" className="text-sm font-[700] text-primary hover:underline">İşletmeleri keşfet →</Link>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            {reviews.map((r) => {
              const author = r.user_profiles?.display_name ?? 'Anonim Gurme';
              const biz = r.businesses;
              const text = r.body ?? r.content;
              return (
                <article key={r.id}
                  className="rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2">
                  {/* Header */}
                  <div className="mb-3 flex items-start gap-3">
                    {/* Avatar */}
                    <div className="h-10 w-10 shrink-0 overflow-hidden rounded-full border border-border bg-primary/10 flex items-center justify-center text-sm font-[900] text-primary">
                      {r.user_profiles?.avatar_url
                        ? // eslint-disable-next-line @next/next/no-img-element
                          <img loading="lazy" src={r.user_profiles.avatar_url} alt={author} className="h-full w-full object-cover" />
                        : author[0]?.toUpperCase() ?? 'G'}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-[800] text-textStrong">{author}</p>
                      {biz && (
                        <Link href={`/isletme/${biz.slug}`}
                          className="text-xs text-muted transition-colors hover:text-primary">
                          {biz.name}
                        </Link>
                      )}
                    </div>
                    <div className="flex shrink-0 flex-col items-end gap-1">
                      {/* Stars */}
                      <div className="flex items-center gap-0.5">
                        {Array.from({ length: 5 }).map((_, i) => (
                          <svg key={i} width="11" height="11" viewBox="0 0 24 24"
                            fill={i < r.rating ? '#f59e0b' : 'none'}
                            stroke={i < r.rating ? '#f59e0b' : '#d1d5db'}
                            strokeWidth="2" aria-hidden="true">
                            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                          </svg>
                        ))}
                      </div>
                      <span className="text-[10px] text-muted">{timeAgo(r.created_at)}</span>
                    </div>
                  </div>

                  {/* Badges */}
                  {r.verified_visit && (
                    <div className="mb-2">
                      <span className="inline-flex items-center gap-1 rounded-full border border-success/25 bg-success/[0.12] px-2 py-0.5 text-[10px] font-[800] text-success">
                        <svg viewBox="0 0 24 24" className="h-2.5 w-2.5 fill-current" aria-hidden="true"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
                        Doğrulanmış Ziyaret
                      </span>
                    </div>
                  )}

                  {/* Content */}
                  {text && (
                    <p className="line-clamp-3 text-sm leading-relaxed text-textStrong">
                      &ldquo;{text}&rdquo;
                    </p>
                  )}

                  {/* Business link */}
                  {biz && (
                    <div className="mt-3 border-t border-border pt-3">
                      <Link href={`/isletme/${biz.slug}`}
                        className="inline-flex items-center gap-1 text-xs font-[700] text-primary hover:underline">
                        {biz.name} sayfasına git →
                      </Link>
                    </div>
                  )}
                </article>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
