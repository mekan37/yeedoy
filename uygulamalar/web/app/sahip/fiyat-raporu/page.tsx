import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Fiyat Raporu | Sahip Paneli',
  robots: { index: false, follow: false },
};

type FiyatSatiri = {
  menu_item_id: string;
  item_name: string;
  business_price_cents: number;
  city_avg_cents: number;
  district_avg_cents: number;
  city_sample_count: number;
  diff_pct: number; // pozitif = biz daha pahalı, negatif = biz daha ucuz
};

function fmtTL(cents: number) {
  return `${(cents / 100).toFixed(2)} ₺`;
}

function diffLabel(pct: number) {
  if (Math.abs(pct) < 5) return { text: 'Ortalamada', cls: 'text-muted', bg: 'bg-border/30' };
  if (pct > 0) return { text: `%${Math.abs(pct).toFixed(0)} pahalı`, cls: 'text-danger', bg: 'bg-danger/[0.08] border border-danger/20' };
  return { text: `%${Math.abs(pct).toFixed(0)} ucuz`, cls: 'text-success', bg: 'bg-success/[0.08] border border-success/20' };
}

export default async function OwnerPriceReportPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? (await getOwnerBusinesses<{
      id: string;
      name: string;
      city: string | null;
      district: string | null;
      is_active: boolean | null;
    }>(supabase as any, user.id, 'id, name, city, district, is_active'))
      .filter((business) => business.is_active !== false)
    : [];

  if (businesses.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Owner" title="Fiyat Raporu" description="Rakip karşılaştırması" />
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState icon={<ChartIcon />} title="İşletme bulunamadı" description="Aktif işletmeniz bulunmuyor." />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  // Her işletme için rakip fiyat karşılaştırması çek
  const reports: Array<{ biz: typeof businesses[0]; rows: FiyatSatiri[] }> = [];

  for (const biz of businesses) {
    let data: FiyatSatiri[] | null = null;
    try {
      const result = await (supabase as any).rpc('get_business_price_comparison_v1', {
        p_business_id: biz.id,
        p_limit: 20,
      });
      data = result.data ?? null;
    } catch {
      data = null;
    }

    reports.push({ biz, rows: data ?? [] });
  }

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Fiyat Raporu"
        description="Menü ürünlerinizin bölge ortalamasıyla karşılaştırması"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {reports.map(({ biz, rows }) => (
            <PanelBolumKarti
              key={biz.id}
              title={`${biz.name}${biz.district ? ` · ${biz.district}` : ''}`}
              noPadding
            >
              {rows.length === 0 ? (
                <p className="px-5 py-4 text-sm text-muted">
                  Bölgenizde henüz karşılaştırma yapılabilecek başka bir işletme bulunmuyor.
                  Bu rapor, aynı şehir veya ilçedeki işletmelerin aynı isimli ürünlerini karşılaştırır —
                  daha fazla işletme menüsünü yayınladıkça burada otomatik olarak veri görünmeye başlayacak.
                </p>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-border bg-cardAlt">
                        <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wider text-muted">Ürün</th>
                        <th className="px-4 py-3 text-right text-xs font-[800] uppercase tracking-wider text-muted">Sizin Fiyatınız</th>
                        <th className="px-4 py-3 text-right text-xs font-[800] uppercase tracking-wider text-muted">İlçe Ort.</th>
                        <th className="px-4 py-3 text-right text-xs font-[800] uppercase tracking-wider text-muted">Şehir Ort.</th>
                        <th className="px-4 py-3 text-center text-xs font-[800] uppercase tracking-wider text-muted">Durum</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {rows.map((row) => {
                        const diff = diffLabel(row.diff_pct);
                        return (
                          <tr key={row.menu_item_id} className="hover:bg-cardAlt/50 transition-colors">
                            <td className="px-5 py-3 font-[700] text-textStrong">{row.item_name}</td>
                            <td className="px-4 py-3 text-right font-[900] text-textStrong">
                              {fmtTL(row.business_price_cents)}
                            </td>
                            <td className="px-4 py-3 text-right text-muted">
                              {row.district_avg_cents > 0 ? fmtTL(row.district_avg_cents) : '—'}
                            </td>
                            <td className="px-4 py-3 text-right text-muted">
                              {row.city_avg_cents > 0 ? fmtTL(row.city_avg_cents) : '—'}
                              {row.city_sample_count > 0 && (
                                <span className="ml-1 text-[10px]">({row.city_sample_count} veri)</span>
                              )}
                            </td>
                            <td className="px-4 py-3 text-center">
                              <span className={`inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${diff.bg} ${diff.cls}`}>
                                {diff.text}
                              </span>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </PanelBolumKarti>
          ))}
        </div>

        {/* Bilgi notu */}
        <div className="mt-4 rounded-xl border border-border bg-cardAlt p-4">
          <p className="text-xs text-muted">
            <span className="font-[800]">Nasıl hesaplanır?</span>{' '}
            Yeedoy topluluğu tarafından doğrulanan fiyatlar kullanılır. Aynı ürün adına sahip diğer işletmelerin ortalama fiyatıyla karşılaştırılır.
            Veri yetersizse satır gösterilmez.
          </p>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function ChartIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/>
    </svg>
  );
}
