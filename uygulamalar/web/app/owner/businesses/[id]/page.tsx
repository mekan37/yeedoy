import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { BusinessEditForm } from './business-edit-form';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('businesses').select('name').eq('id', id).single() as { data: { name: string } | null };
  return {
    title: data ? `${data.name} | Owner Panel` : 'İşletme | Owner Panel',
    robots: { index: false, follow: false },
  };
}

export default async function BusinessDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type FullBiz = { id: string; name: string; slug: string | null; category: string; description: string | null; phone: string | null; address: string | null; city: string | null; district: string | null; neighborhood: string | null; lat: number | null; lng: number | null; is_active: boolean; logo_url: string | null; cover_url: string | null; reservation_url: string | null; order_yemeksepeti_url: string | null; order_trendyolgo_url: string | null; order_getir_url: string | null };
  const { data: business } = await (supabase as any)
    .from('businesses')
    .select(
      'id, name, slug, category, description, phone, address, city, district, ' +
      'neighborhood, lat, lng, is_active, logo_url, cover_url, ' +
      'reservation_url, order_yemeksepeti_url, order_trendyolgo_url, order_getir_url',
    )
    .eq('id', id)
    .eq('owner_id', user!.id)
    .single() as { data: FullBiz | null };

  if (!business) notFound();

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="İşletmeler"
        title={business.name}
        description={business.category}
      />
      <PanelContentSurface className="pt-6">
        <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
          {/* Main info */}
          <div className="lg:col-span-2">
            <PanelSectionCard title="Temel Bilgiler">
              <BusinessEditForm business={business} />
            </PanelSectionCard>
          </div>

          {/* Side info */}
          <div className="flex flex-col gap-5">
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
                <span className="text-xs text-muted">{business.slug ?? '—'}</span>
              </div>
            </PanelSectionCard>

            <PanelSectionCard title="Konum">
              <dl className="space-y-2 text-sm">
                <div>
                  <dt className="text-xs font-[700] uppercase tracking-wide text-muted">Şehir</dt>
                  <dd className="mt-0.5 text-textStrong">{business.city ?? '—'}</dd>
                </div>
                <div>
                  <dt className="text-xs font-[700] uppercase tracking-wide text-muted">İlçe</dt>
                  <dd className="mt-0.5 text-textStrong">{business.district ?? '—'}</dd>
                </div>
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

            <PanelSectionCard title="Sipariş Linkleri">
              <dl className="space-y-2 text-sm">
                {[
                  { label: 'Yemeksepeti', value: business.order_yemeksepeti_url },
                  { label: 'Trendyol GO', value: business.order_trendyolgo_url },
                  { label: 'Getir', value: business.order_getir_url },
                  { label: 'Rezervasyon', value: business.reservation_url },
                ].map(({ label, value }) => (
                  value ? (
                    <div key={label}>
                      <dt className="text-xs font-[700] uppercase tracking-wide text-muted">{label}</dt>
                      <dd className="mt-0.5 truncate text-xs text-[color:var(--yd-color-primary)]">
                        <a href={value} target="_blank" rel="noopener noreferrer">{value}</a>
                      </dd>
                    </div>
                  ) : null
                ))}
              </dl>
            </PanelSectionCard>
          </div>
        </div>
      </PanelContentSurface>
    </div>
  );
}
