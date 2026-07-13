import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createSupabaseServiceClient } from '@/src/lib/supabase/service';
import { canManageBusiness } from '@/src/lib/qr-access';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { BusinessEditForm } from './business-edit-form';
import { BrandingEditor } from '@/app/sahip/isletmeler/[id]/marka-editoru';
import { MealCardEditor } from '@/app/sahip/isletmeler/[id]/yemek-karti-editoru';
import type { MealCardProvider } from '@/app/sahip/isletmeler/[id]/yemek-karti-editoru';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any)
    .from('businesses').select('name').eq('id', id).single() as { data: { name: string } | null };
  return {
    title: data ? `${data.name} | Owner Panel` : 'İşletme | Owner Panel',
    robots: { index: false, follow: false },
  };
}

export default async function BusinessDetailPage({ params }: Props) {
  const { id } = await params;

  // Yetki kontrolü: can_manage_business_v1 RPC (owner_claims tablosuna bakar)
  const canManage = await canManageBusiness(id);
  if (!canManage) notFound();

  const service = createSupabaseServiceClient();
  if (!service) notFound();

  type FullBiz = {
    id: string; name: string; slug: string | null; category: string;
    description: string | null; phone: string | null; address: string | null;
    city: string | null; district: string | null; neighborhood: string | null;
    lat: number | null; lng: number | null; is_active: boolean; is_verified: boolean;
    logo_url: string | null; cover_url: string | null;
    reservation_url: string | null;
    order_yemeksepeti_url: string | null; order_trendyolgo_url: string | null;
    order_getir_url: string | null;
  };

  const { data: business } = await (service as any)
    .from('businesses')
    .select(
      'id, name, slug, category, description, phone, address, city, district, ' +
      'neighborhood, lat, lng, is_active, is_verified, logo_url, cover_url, ' +
      'reservation_url, order_yemeksepeti_url, order_trendyolgo_url, order_getir_url',
    )
    .eq('id', id)
    .single() as { data: FullBiz | null };

  if (!business) notFound();

  // Meal card sorguları auth bağlamı gerektiriyor → server client
  const supabase = await createSupabaseServerClient();
  type MealCardProviderRow = { id: string; key: string; name: string; asset_name: string; sort_order: number };
  type SelectedMealCardRow = { key: string };

  const [allProvidersResult, selectedProvidersResult] = await Promise.all([
    (supabase as any)
      .from('meal_card_providers')
      .select('id, key, name, asset_name, sort_order')
      .eq('is_active', true)
      .order('sort_order') as Promise<{ data: MealCardProviderRow[] | null }>,
    (supabase as any)
      .rpc('get_business_meal_card_providers_v1', { p_business_id: id }) as Promise<{ data: SelectedMealCardRow[] | null }>,
  ]);

  const allProviders: MealCardProvider[] = (allProvidersResult.data ?? []).map((row) => ({
    id: row.id, key: row.key, name: row.name, assetName: row.asset_name, sortOrder: row.sort_order,
  }));
  const selectedKeys: string[] = (selectedProvidersResult.data ?? []).map((row) => row.key);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="İşletmeler"
        title={business.name}
        description={[
          business.category,
          business.is_verified ? '✓ Doğrulanmış' : null,
          business.slug ? `yeedoy.com/${business.slug}` : null,
        ].filter(Boolean).join(' · ')}
        actions={
          business.slug ? (
            <Link
              href={`/m/${business.slug}`}
              target="_blank"
              className="flex h-9 items-center gap-2 rounded-xl border border-border px-4 text-sm font-[800] text-textStrong transition hover:bg-bg"
            >
              <ExternalIcon />
              Menüyü Gör
            </Link>
          ) : undefined
        }
      />

      <PanelContentSurface className="pt-4">
        <div className="flex flex-col gap-5">

          {/* ── Marka görselleri ─────────────────────────────────────────── */}
          <BrandingEditor
            businessId={id}
            initialLogoUrl={business.logo_url}
            initialCoverUrl={business.cover_url}
            businessName={business.name}
          />

          {/* ── Ana içerik ─────────────────────────────────────────────── */}
          <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">

            {/* Sol: form */}
            <div className="flex flex-col gap-5 lg:col-span-2">
              <PanelSectionCard title="İşletme Bilgileri">
                <BusinessEditForm business={business} />
              </PanelSectionCard>
            </div>

            {/* Sağ: durum + konum + yemek kartları */}
            <div className="flex flex-col gap-5">

              {/* Durum */}
              <PanelSectionCard title="Durum">
                <div className="flex items-center gap-3">
                  <span
                    className={`rounded-full px-3 py-1 text-xs font-[800] ${
                      business.is_active
                        ? 'bg-green-50 text-green-700'
                        : 'bg-zinc-100 text-zinc-500'
                    }`}
                  >
                    {business.is_active ? 'Aktif' : 'Pasif'}
                  </span>
                  {business.slug && (
                    <span className="text-xs text-muted">/{business.slug}</span>
                  )}
                </div>
              </PanelSectionCard>

              {/* Konum */}
              {(business.city || business.district || (business.lat && business.lng)) && (
                <PanelSectionCard title="Konum">
                  <dl className="space-y-2 text-sm">
                    {business.city && (
                      <div>
                        <dt className="text-xs font-[700] uppercase tracking-wide text-muted">Şehir</dt>
                        <dd className="mt-0.5 text-textStrong">{business.city}</dd>
                      </div>
                    )}
                    {business.district && (
                      <div>
                        <dt className="text-xs font-[700] uppercase tracking-wide text-muted">İlçe</dt>
                        <dd className="mt-0.5 text-textStrong">{business.district}</dd>
                      </div>
                    )}
                    {business.lat && business.lng && (
                      <div>
                        <dt className="text-xs font-[700] uppercase tracking-wide text-muted">Koordinat</dt>
                        <dd className="mt-0.5 font-mono text-xs text-muted">
                          {business.lat.toFixed(6)}, {business.lng.toFixed(6)}
                        </dd>
                      </div>
                    )}
                  </dl>
                </PanelSectionCard>
              )}

              {/* Yemek Kartları */}
              {allProviders.length > 0 && (
                <PanelSectionCard title="Yemek Kartları">
                  <MealCardEditor
                    businessId={id}
                    allProviders={allProviders}
                    selectedKeys={selectedKeys}
                  />
                </PanelSectionCard>
              )}
            </div>
          </div>
        </div>
      </PanelContentSurface>
    </div>
  );
}

// ── Icons ──────────────────────────────────────────────────────────────────

function ExternalIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
      <polyline points="15 3 21 3 21 9" />
      <line x1="10" y1="14" x2="21" y2="3" />
    </svg>
  );
}
