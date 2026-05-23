import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Grup İstekleri | Sahip Paneli',
  robots: { index: false, follow: false },
};

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  open: { label: 'Açık', className: 'bg-green-50 text-green-700' },
  closed: { label: 'Kapalı', className: 'bg-zinc-100 text-zinc-500' },
  awarded: { label: 'Tamamlandı', className: 'bg-blue-50 text-blue-700' },
  cancelled: { label: 'İptal', className: 'bg-red-50 text-red-700' },
};

function formatPrice(cents: number, currency: string) {
  return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: currency || 'TRY', minimumFractionDigits: 0 }).format(cents / 100);
}

export default async function OwnerRequestsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ city: string | null; category: string | null }>(
      supabase as any,
      user.id,
      'city, category',
    )
    : [];

  const cities = [...new Set(businesses.map((b: any) => b.city).filter(Boolean))] as string[];
  const categories = [...new Set(businesses.map((b: any) => b.category).filter(Boolean))] as string[];

  const { data: requests } = cities.length > 0
    ? await (supabase as any)
        .from('group_requests')
        .select('id, city, districts, category, date_time, party_size, budget_total_cents, currency, notes, status, created_at')
        .in('city', cities)
        .eq('status', 'open')
        .order('date_time', { ascending: true })
        .limit(50)
    : { data: [] };

  const list = (requests ?? []) as any[];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Grup İstekleri"
        description={`${list.length} açık talep · Şehirlerinize gelen organizasyon istekleri`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {cities.length === 0 && (
          <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800 mb-4">
            İşletmenize ait şehir bilgisi bulunmuyor. Grup isteklerini görüntülemek için işletme bilgilerinizi güncelleyin.
          </div>
        )}
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<UsersIcon />}
            title="Şu an açık grup isteği yok"
            description={cities.length > 0 ? `${cities.join(', ')} için açık organizasyon talebi bulunmuyor.` : 'Önce işletme ekleyin.'}
          />
        ) : (
          <PanelBolumKarti noPadding>
            <ul className="divide-y divide-border">
              {list.map((r: any) => {
                const statusInfo = STATUS_MAP[r.status] ?? STATUS_MAP['open'];
                const isRelevantCategory = categories.some(
                  (c) => !r.category || r.category.toLowerCase().includes(c.toLowerCase()) || c.toLowerCase().includes(r.category?.toLowerCase() ?? ''),
                );
                return (
                  <li key={r.id} className="px-5 py-4">
                    <div className="flex items-start justify-between gap-4">
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-2">
                          <p className="text-sm font-[800] text-textStrong">
                            {r.party_size} kişilik · {formatPrice(r.budget_total_cents, r.currency)} bütçe
                          </p>
                          {isRelevantCategory && (
                            <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-[700] text-primary">
                              Uygun Kategori
                            </span>
                          )}
                        </div>
                        <p className="mt-0.5 text-xs text-muted">
                          {r.city}
                          {r.districts?.length > 0 ? ` · ${r.districts.join(', ')}` : ''}
                          {r.category ? ` · ${r.category}` : ''}
                        </p>
                        <p className="mt-0.5 text-xs text-muted">
                          {new Date(r.date_time).toLocaleDateString('tr-TR', {
                            weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
                          })}
                        </p>
                        {r.notes && (
                          <p className="mt-1.5 line-clamp-2 text-xs text-muted italic">&ldquo;{r.notes}&rdquo;</p>
                        )}
                      </div>
                      <span className={`shrink-0 rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${statusInfo.className}`}>
                        {statusInfo.label}
                      </span>
                    </div>
                  </li>
                );
              })}
            </ul>
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function UsersIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}

