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
    created_at: string;
  };
  const businessIds = await getOwnerBusinessIds(supabase as any, user!.id);
  const { data: businesses } = businessIds.length > 0
    ? await (supabase as any)
        .from('businesses')
        .select('id, name, slug, logo_url, cover_url, category, city, district, lat, lng, is_active, created_at')
        .in('id', businessIds)
        .order('created_at', { ascending: false }) as { data: BizRow[] | null }
    : { data: [] };

  const list = businesses ?? [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Sahip"
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
              {list.map((b) => (
                <PanelBolumKarti key={b.id} noPadding className="overflow-hidden">
                  <Link
                    href={`/sahip/isletmeler/${b.id}`}
                    className="group block transition-colors hover:bg-black/2"
                  >
                    <div
                      className="relative min-h-[150px] bg-[linear-gradient(135deg,#171717,#525252)]"
                      style={b.cover_url ? {
                        backgroundImage: `linear-gradient(90deg, rgba(0,0,0,.62), rgba(0,0,0,.14)), url("${buildMenuImageUrl(b.cover_url, { width: 900, quality: 80 }) ?? ''}")`,
                        backgroundSize: 'cover',
                        backgroundPosition: 'center',
                      } : undefined}
                    >
                      <div className="absolute inset-x-0 bottom-0 flex items-end gap-3 p-4 text-white">
                        <div className="flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-2xl border border-white/25 bg-white/15 text-2xl font-black shadow-yd2 backdrop-blur-sm">
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
                          <p className="truncate text-lg font-black">{b.name}</p>
                          <p className="truncate text-xs font-bold text-white/75">
                            {[b.category, b.district, b.city].filter(Boolean).join(' · ') || 'İşletme profili'}
                          </p>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center justify-between gap-3 px-4 py-3">
                      <div className="flex flex-wrap gap-2">
                        <span
                          className={`shrink-0 rounded-full px-2.5 py-0.5 text-[11px] font-extrabold ${
                            b.is_active
                              ? 'bg-green-50 text-green-700'
                              : 'bg-zinc-100 text-zinc-500'
                          }`}
                        >
                          {b.is_active ? 'Aktif' : 'Pasif'}
                        </span>
                        <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-extrabold ${
                          b.lat && b.lng ? 'bg-primary/8 text-primary' : 'bg-amber-50 text-amber-700'
                        }`}>
                          {b.lat && b.lng ? 'Konum var' : 'Konum eksik'}
                        </span>
                        <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-extrabold ${
                          b.logo_url && b.cover_url ? 'bg-blue-50 text-blue-700' : 'bg-zinc-100 text-zinc-600'
                        }`}>
                          {b.logo_url && b.cover_url ? 'Görseller hazır' : 'Görsel eksik'}
                        </span>
                      </div>
                      <ChevronIcon />
                    </div>
                  </Link>
                </PanelBolumKarti>
              ))}
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

