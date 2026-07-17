import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { buildMenuImageUrl } from '@/src/lib/media-url';

export const metadata: Metadata = {
  title: 'İşletmeler | Owner Panel',
  robots: { index: false, follow: false },
};

type BizRow = {
  id: string;
  name: string;
  slug: string | null;
  logo_url: string | null;
  cover_url: string | null;
  category: string | null;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
};

type BizStats = {
  id: string;
  avg_rating: number | null;
  reviews_count: number;
};

export default async function OwnerBusinessesPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  // Fetch businesses via owner_claims (businesses don't have owner_id directly)
  const { data: claims } = await (supabase as any)
    .from('owner_claims')
    .select('business_id, businesses(id, name, slug, logo_url, cover_url, category, is_active, is_verified, created_at)')
    .eq('user_id', user.id)
    .eq('status', 'approved')
    .order('created_at', { ascending: false }) as {
      data: { business_id: string; businesses: BizRow }[] | null;
    };

  const list: BizRow[] = (claims ?? []).map((c) => c.businesses).filter(Boolean);
  const bizIds = list.map((b) => b.id);

  // Fetch stats for all businesses in one query
  const statsMap: Record<string, BizStats> = {};
  if (bizIds.length > 0) {
    const { data: statsRows } = await (supabase as any)
      .from('businesses_with_stats')
      .select('id, avg_rating, reviews_count')
      .in('id', bizIds) as { data: BizStats[] | null };
    for (const s of statsRows ?? []) statsMap[s.id] = s;
  }

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="İşletmeler"
        description="Sahip olduğunuz işletmeleri görüntüleyin ve yönetin"
        actions={
          <Link
            href="/owner/businesses/new"
            className="flex h-9 items-center gap-2 rounded-xl bg-[#dc2626] px-4 text-sm font-[800] text-white shadow-[0_2px_6px_rgba(220,38,38,0.25)] transition hover:bg-[#b91c1c]"
          >
            <PlusIcon />
            Yeni İşletme
          </Link>
        }
      />

      <div className="px-6 pb-8 pt-2">
        {list.length === 0 ? (
          /* ── Empty state ── */
          <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-[#e5e7eb] bg-[#fafafa] py-20 text-center">
            <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-[#f3f4f6]">
              <BuildingIcon />
            </div>
            <p className="text-base font-[800] text-[#1a1a2e]">Henüz işletme yok</p>
            <p className="mt-1 text-sm text-[#94a3b8]">
              Yeedoy&apos;da sahip olduğunuz işletme bulunamadı.
            </p>
            <Link
              href="/owner/businesses/new"
              className="mt-6 flex h-10 items-center gap-2 rounded-xl bg-[#dc2626] px-5 text-sm font-[800] text-white shadow-[0_2px_6px_rgba(220,38,38,0.25)] transition hover:bg-[#b91c1c]"
            >
              <PlusIcon />
              İşletme Ekle
            </Link>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {list.map((biz) => {
              const stats = statsMap[biz.id];
              const coverUrl = biz.cover_url
                ? buildMenuImageUrl(biz.cover_url, { width: 600, quality: 75 })
                : null;
              const logoUrl = biz.logo_url
                ? buildMenuImageUrl(biz.logo_url, { width: 80, quality: 80 })
                : null;
              const avgRating = stats?.avg_rating ?? null;
              const reviewsCount = stats?.reviews_count ?? 0;

              return (
                <div
                  key={biz.id}
                  className="group overflow-hidden rounded-2xl border border-[#f0f0f0] bg-white shadow-[0_1px_3px_rgba(0,0,0,0.04)] transition hover:shadow-[0_4px_16px_rgba(0,0,0,0.08)]"
                >
                  {/* Cover */}
                  <div className="relative h-[140px] bg-gradient-to-br from-[#5c1515] to-[#dc2626]">
                    {coverUrl && (
                      <Image
                        src={coverUrl}
                        alt={biz.name}
                        fill
                        sizes="(max-width:640px) 100vw, (max-width:1280px) 50vw, 33vw"
                        className="object-cover"
                      />
                    )}
                    {/* Status pill */}
                    <div className="absolute right-3 top-3">
                      <span
                        className={`rounded-full px-2.5 py-1 text-[11px] font-[800] backdrop-blur-sm ${
                          biz.is_active
                            ? 'bg-green-500/90 text-white'
                            : 'bg-black/40 text-white/80'
                        }`}
                      >
                        {biz.is_active ? 'Aktif' : 'Pasif'}
                      </span>
                    </div>
                    {/* Logo */}
                    <div className="absolute bottom-0 left-5 translate-y-1/2">
                      <div className="h-14 w-14 overflow-hidden rounded-2xl border-[3px] border-white bg-white shadow-md">
                        {logoUrl ? (
                          <Image
                            src={logoUrl}
                            alt={biz.name}
                            width={56}
                            height={56}
                            className="h-full w-full object-cover"
                          />
                        ) : (
                          <div className="flex h-full w-full items-center justify-center bg-[#f1f5f9] text-xl font-[900] text-[#dc2626]">
                            {biz.name.charAt(0).toUpperCase()}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Body */}
                  <div className="px-5 pb-5 pt-10">
                    {/* Name + verified */}
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-1.5">
                          <p className="truncate text-[15px] font-[900] text-[#1a1a2e]">{biz.name}</p>
                          {biz.is_verified && (
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0">
                              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                              <polyline points="22 4 12 14.01 9 11.01" />
                            </svg>
                          )}
                        </div>
                        {biz.category && (
                          <p className="mt-0.5 text-[12px] text-[#94a3b8] font-[600]">{biz.category}</p>
                        )}
                      </div>
                    </div>

                    {/* Stats row */}
                    <div className="mt-3 flex items-center gap-4 text-[12px] text-[#64748b]">
                      {avgRating != null ? (
                        <span className="flex items-center gap-1 font-[800] text-[#f59e0b]">
                          <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" strokeWidth="0">
                            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                          </svg>
                          <span className="text-[#1a1a2e]">{avgRating.toFixed(1)}</span>
                          <span className="font-[600] text-[#94a3b8]">({reviewsCount})</span>
                        </span>
                      ) : (
                        <span className="text-[#cbd5e1] font-[600]">Henüz yorum yok</span>
                      )}
                      {biz.slug && (
                        <>
                          <span className="h-3 w-px bg-[#e2e8f0]" />
                          <span className="font-[600] text-[#94a3b8]">{`yeedoy.com/${biz.slug}`}</span>
                        </>
                      )}
                    </div>

                    {/* Actions */}
                    <div className="mt-4 flex gap-2">
                      <Link
                        href={`/owner/businesses/${biz.id}`}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-[#e2e8f0] py-2 text-[12px] font-[800] text-[#475569] transition hover:bg-[#f8fafc]"
                      >
                        <EditIcon />
                        Düzenle
                      </Link>
                      <Link
                        href="/owner/menus"
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-[#e2e8f0] py-2 text-[12px] font-[800] text-[#475569] transition hover:bg-[#f8fafc]"
                      >
                        <MenuIcon />
                        Menü
                      </Link>
                      {biz.slug && (
                        <Link
                          href={`/m/${biz.slug}`}
                          target="_blank"
                          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-[#e2e8f0] text-[#94a3b8] transition hover:border-[#dc2626]/40 hover:text-[#dc2626]"
                          title="Menüyü Görüntüle"
                        >
                          <ExternalIcon />
                        </Link>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}

            {/* Add new card */}
            <Link
              href="/owner/businesses/new"
              className="flex min-h-[260px] flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed border-[#e5e7eb] bg-[#fafafa] text-center transition hover:border-[#dc2626]/40 hover:bg-[#fef2f2]"
            >
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#f3f4f6] text-[#dc2626] transition group-hover:bg-[#fecaca]">
                <PlusIcon size={20} />
              </div>
              <div>
                <p className="text-sm font-[800] text-[#374151]">Yeni İşletme Ekle</p>
                <p className="mt-0.5 text-[12px] text-[#9ca3af]">Yeedoy&apos;a yeni işletme ekleyin</p>
              </div>
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}

function BuildingIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" />
      <path d="M9 22V12h6v10" />
      <path d="M9 7h1m4 0h1M9 11h1m4 0h1" />
    </svg>
  );
}

function PlusIcon({ size = 14 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
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

function MenuIcon() {
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
