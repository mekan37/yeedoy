import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';

export const metadata: Metadata = {
  title: 'İşletmeler | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerBusinessesPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type BizRow = {
    id: string;
    name: string;
    slug: string | null;
    logo_url: string | null;
    cover_url: string | null;
    category: string;
    city: string | null;
    district: string | null;
    lat: number | null;
    lng: number | null;
    is_active: boolean;
    is_verified: boolean;
    created_at: string;
  };
  type BizStats = { id: string; avg_rating: number | null; reviews_count: number };

  const businessIds = await getOwnerBusinessIds(supabase as any, user!.id);
  const { data: businesses } = businessIds.length > 0
    ? await (supabase as any)
        .from('businesses')
        .select('id, name, slug, logo_url, cover_url, category, city, district, lat, lng, is_active, is_verified, created_at')
        .in('id', businessIds)
        .order('created_at', { ascending: false }) as { data: BizRow[] | null }
    : { data: [] };

  const list = businesses ?? [];

  const statsMap: Record<string, BizStats> = {};
  if (list.length > 0) {
    const { data: statsRows } = await (supabase as any)
      .from('businesses_with_stats')
      .select('id, avg_rating, reviews_count')
      .in('id', list.map((b) => b.id)) as { data: BizStats[] | null };
    for (const s of statsRows ?? []) statsMap[s.id] = s;
  }

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="İşletmeler"
        description="Sahip olduğunuz işletmeleri yönetin"
        actions={
          <Link href="/sahip/isletmeler/yeni">
            <PanelActionButton variant="primary" icon={<PlusIcon />}>
              Yeni İşletme
            </PanelActionButton>
          </Link>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<BuildingIcon />}
            title="Henüz işletme yok"
            description="İlk işletmenizi ekleyerek başlayın."
            action={
              <Link href="/sahip/isletmeler/yeni">
                <PanelActionButton variant="primary" icon={<PlusIcon />}>
                  İşletme Ekle
                </PanelActionButton>
              </Link>
            }
          />
        ) : (
          <div className="grid gap-4 lg:grid-cols-2">
              {list.map((b) => {
                const stats = statsMap[b.id];
                const avgRating = stats?.avg_rating ?? null;
                const reviewsCount = stats?.reviews_count ?? 0;
                return (
                  <PanelBolumKarti key={b.id} noPadding className="overflow-hidden">
                    <Link
                      href={`/sahip/isletmeler/${b.id}`}
                      className="group block transition-colors hover:bg-black/[0.02]"
                    >
                      <div
                        className="relative min-h-[150px] bg-[linear-gradient(135deg,_#171717,_#525252)]"
                        style={b.cover_url ? {
                          backgroundImage: `linear-gradient(90deg, rgba(0,0,0,.62), rgba(0,0,0,.14)), url("${buildMenuImageUrl(b.cover_url, { width: 900, quality: 80 }) ?? ''}")`,
                          backgroundSize: 'cover',
                          backgroundPosition: 'center',
                        } : undefined}
                      >
                        <div className="absolute right-3 top-3">
                          <span
                            className={`rounded-full px-2.5 py-1 text-[11px] font-[800] backdrop-blur-sm ${
                              b.is_active
                                ? 'bg-green-500/90 text-white'
                                : 'bg-black/40 text-white/80'
                            }`}
                          >
                            {b.is_active ? 'Aktif' : 'Pasif'}
                          </span>
                        </div>
                        <div className="absolute inset-x-0 bottom-0 flex items-end gap-3 p-4 text-white">
                          <div className="flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-2xl border border-white/25 bg-white/15 text-2xl font-[900] shadow-yd2 backdrop-blur">
                            {b.logo_url ? (
                              // eslint-disable-next-line @next/next/no-img-element
                              <img
                                src={buildMenuImageUrl(b.logo_url, { width: 160, quality: 84 }) ?? ''}
                                alt={b.name}
                                className="h-full w-full object-cover"
                              />
                            ) : (
                              b.name.charAt(0).toUpperCase()
                            )}
                          </div>
                          <div className="min-w-0 pb-1">
                            <div className="flex items-center gap-1.5">
                              <p className="truncate text-lg font-[900]">{b.name}</p>
                              {b.is_verified && (
                                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0">
                                  <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                                  <polyline points="22 4 12 14.01 9 11.01" />
                                </svg>
                              )}
                            </div>
                            <p className="truncate text-xs font-[700] text-white/75">
                              {[b.category, b.district, b.city].filter(Boolean).join(' · ') || 'İşletme profili'}
                            </p>
                          </div>
                        </div>
                      </div>

                      <div className="flex flex-wrap items-center justify-between gap-2 px-4 py-2.5">
                        <div className="flex flex-wrap items-center gap-3 text-xs text-muted">
                          {avgRating != null ? (
                            <span className="flex items-center gap-1 font-[800] text-amber-500">
                              <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" strokeWidth="0">
                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                              </svg>
                              <span className="text-textStrong">{avgRating.toFixed(1)}</span>
                              <span className="font-[600] text-muted">({reviewsCount})</span>
                            </span>
                          ) : (
                            <span className="font-[600] text-muted">Henüz yorum yok</span>
                          )}
                          {b.slug && (
                            <>
                              <span className="h-3 w-px bg-border" />
                              <span className="truncate font-[600] text-muted">{`yeedoy.com/${b.slug}`}</span>
                            </>
                          )}
                          {(!b.lat || !b.lng) && (
                            <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-[800] text-amber-700">
                              Konum eksik
                            </span>
                          )}
                          {!(b.logo_url && b.cover_url) && (
                            <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[11px] font-[800] text-zinc-600">
                              Görsel eksik
                            </span>
                          )}
                        </div>
                        <ChevronIcon />
                      </div>
                    </Link>
                    <div className="flex gap-2 border-t border-border px-4 py-2.5">
                      <Link
                        href={`/sahip/isletmeler/${b.id}`}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-border py-2 text-xs font-[800] text-textStrong transition hover:bg-bg"
                      >
                        <EditIcon />
                        Düzenle
                      </Link>
                      <Link
                        href="/sahip/menuler"
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-border py-2 text-xs font-[800] text-textStrong transition hover:bg-bg"
                      >
                        <MenuShortcutIcon />
                        Menü
                      </Link>
                      {b.slug && (
                        <Link
                          href={`/m/${b.slug}`}
                          target="_blank"
                          title="Menüyü Görüntüle"
                          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-border text-muted transition hover:border-primary/40 hover:text-primary"
                        >
                          <ExternalIcon />
                        </Link>
                      )}
                    </div>
                  </PanelBolumKarti>
                );
              })}

              <Link
                href="/sahip/isletmeler/yeni"
                className="flex min-h-[260px] flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed border-border bg-bg text-center transition hover:border-primary/40 hover:bg-primary/[0.04]"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-card text-primary">
                  <PlusIcon />
                </div>
                <div>
                  <p className="text-sm font-[800] text-textStrong">Yeni İşletme Ekle</p>
                  <p className="mt-0.5 text-xs text-muted">Yeedoy&apos;a yeni işletme ekleyin</p>
                </div>
              </Link>
          </div>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function BuildingIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" />
      <path d="M9 22V12h6v10" />
    </svg>
  );
}

function PlusIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}

function ChevronIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
      <polyline points="9 18 15 12 9 6" />
    </svg>
  );
}

function EditIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
    </svg>
  );
}

function MenuShortcutIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
    </svg>
  );
}

function ExternalIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
      <polyline points="15 3 21 3 21 9" />
      <line x1="10" y1="14" x2="21" y2="3" />
    </svg>
  );
}

