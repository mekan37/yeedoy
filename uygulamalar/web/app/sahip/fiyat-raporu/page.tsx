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

// Fiyat konumu çubuğu: 0 = ortalamanın çok altı, 50 = ortalama, 100 = ortalamanın çok üstü
function positionPct(diffPct: number) {
  const clamped = Math.max(-50, Math.min(50, diffPct));
  return 50 + clamped;
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

  const allRows = reports.flatMap((r) => r.rows);
  const totalCompared = allRows.length;
  const pricierCount = allRows.filter((r) => r.diff_pct > 5).length;
  const cheaperCount = allRows.filter((r) => r.diff_pct < -5).length;
  const averageCount = totalCompared - pricierCount - cheaperCount;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Fiyat Raporu"
        description="Menü ürünlerinizin bölge ortalamasıyla karşılaştırması"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {totalCompared > 0 && (
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <PriceKpiCard label="Karşılaştırılan Ürün" value={String(totalCompared)} icon={<ChartIcon />} tone="neutral" />
              <PriceKpiCard label="Pahalı Ürün" value={String(pricierCount)} icon={<ArrowUpIcon />} tone="danger" />
              <PriceKpiCard label="Ortalamada" value={String(averageCount)} icon={<EqualsIcon />} tone="neutral" />
              <PriceKpiCard label="Ucuz Ürün" value={String(cheaperCount)} icon={<ArrowDownIcon />} tone="success" />
            </div>
          )}

          {reports.map(({ biz, rows }) => {
            const bizAvgDiff = rows.length > 0
              ? rows.reduce((sum, r) => sum + r.diff_pct, 0) / rows.length
              : null;
            const bizDiff = bizAvgDiff !== null ? diffLabel(bizAvgDiff) : null;

            return (
              <PanelBolumKarti
                key={biz.id}
                title={`${biz.name}${biz.district ? ` · ${biz.district}` : ''}`}
                actions={
                  bizDiff && (
                    <span className={`inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${bizDiff.bg} ${bizDiff.cls}`}>
                      Ortalama {bizDiff.text}
                    </span>
                  )
                }
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
                          <th className="px-4 py-3 text-center text-xs font-[800] uppercase tracking-wider text-muted">Konum</th>
                          <th className="px-4 py-3 text-center text-xs font-[800] uppercase tracking-wider text-muted">Durum</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-border">
                        {rows.map((row) => {
                          const diff = diffLabel(row.diff_pct);
                          const pos = positionPct(row.diff_pct);
                          return (
                            <tr key={row.menu_item_id} className="transition-colors hover:bg-cardAlt/50">
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
                              <td className="px-4 py-3">
                                <div className="relative mx-auto h-1.5 w-24 rounded-full bg-border">
                                  <span className="absolute left-1/2 top-1/2 h-3 w-px -translate-x-1/2 -translate-y-1/2 bg-muted/50" />
                                  <span
                                    className={`absolute top-1/2 h-2.5 w-2.5 -translate-y-1/2 -translate-x-1/2 rounded-full border-2 border-card ${
                                      Math.abs(row.diff_pct) < 5 ? 'bg-muted' : row.diff_pct > 0 ? 'bg-danger' : 'bg-success'
                                    }`}
                                    style={{ left: `${pos}%` }}
                                  />
                                </div>
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
            );
          })}
        </div>

        {/* Bilgi notu */}
        <div className="mt-4 flex items-start gap-3 rounded-xl border border-border bg-cardAlt p-4">
          <InfoIcon />
          <p className="text-xs text-muted">
            <span className="font-[800] text-textStrong">Nasıl hesaplanır?</span>{' '}
            Yeedoy topluluğu tarafından doğrulanan fiyatlar kullanılır. Aynı ürün adına sahip diğer işletmelerin
            ortalama fiyatıyla karşılaştırılır. &ldquo;Konum&rdquo; çubuğu ürününüzün bölge ortalamasına göre
            nerede durduğunu gösterir — orta çizgi ortalamayı, nokta sizin fiyatınızı temsil eder.
            Veri yetersizse satır gösterilmez.
          </p>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function PriceKpiCard({
  label, value, icon, tone,
}: {
  label: string; value: string; icon: React.ReactNode; tone: 'neutral' | 'danger' | 'success';
}) {
  const toneClasses = {
    neutral: 'bg-bg text-muted',
    danger: 'bg-danger/[0.08] text-danger',
    success: 'bg-success/[0.08] text-success',
  }[tone];
  return (
    <div className="rounded-2xl border border-border bg-card p-4 shadow-sm">
      <div className={`mb-3 flex h-9 w-9 items-center justify-center rounded-xl ${toneClasses}`}>
        {icon}
      </div>
      <p className="text-xs font-[700] text-muted">{label}</p>
      <p className="mt-1 text-2xl font-[900] text-textStrong">{value}</p>
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

function ArrowUpIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="19" x2="12" y2="5" /><polyline points="5 12 12 5 19 12" />
    </svg>
  );
}

function ArrowDownIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" /><polyline points="19 12 12 19 5 12" />
    </svg>
  );
}

function EqualsIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="5" y1="9" x2="19" y2="9" /><line x1="5" y1="15" x2="19" y2="15" />
    </svg>
  );
}

function InfoIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mt-0.5 shrink-0 text-muted">
      <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />
    </svg>
  );
}
