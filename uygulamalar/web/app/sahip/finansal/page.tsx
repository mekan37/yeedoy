import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Finansal Raporlar | Sahip Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ ay?: string }> };

function fmtTL(cents: number) {
  return `₺${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}`;
}

// KDV oranı %18 (Türkiye restoran hizmet KDV)
const KDV_ORANI = 0.18;

function ayListesi() {
  const sonuc = [];
  const simdi = new Date();
  for (let i = 0; i < 12; i++) {
    const d = new Date(simdi.getFullYear(), simdi.getMonth() - i, 1);
    const key = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`;
    const label = d.toLocaleDateString('tr-TR', { month: 'long', year: 'numeric' });
    sonuc.push({ key, label });
  }
  return sonuc;
}

export default async function FinansalRaporlarPage({ searchParams }: Props) {
  const params = await searchParams;
  const simdi = new Date();
  const varsayilanAy = `${simdi.getFullYear()}-${String(simdi.getMonth()+1).padStart(2,'0')}`;
  const seciliAy = /^\d{4}-\d{2}$/.test(params.ay ?? '') ? params.ay! : varsayilanAy;

  const [yil, ay] = seciliAy.split('-').map(Number);
  const ayBaslangic = new Date(yil, ay - 1, 1).toISOString();
  const aySonu = new Date(yil, ay, 1).toISOString();

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(
        supabase as any,
        user.id,
        'id, name',
      )
    : [];

  const businessIds = businesses.map((b) => b.id);
  const bizMap = Object.fromEntries(businesses.map((b) => [b.id, b.name]));

  // Sipariş kalemleri bu ay
  const { data: siparisKalemleri } = businessIds.length > 0
    ? await (supabase as any)
        .from('table_order_items')
        .select('business_id, price, quantity, created_at')
        .in('business_id', businessIds)
        .gte('created_at', ayBaslangic)
        .lt('created_at', aySonu)
    : { data: [] };

  const kalemler = (siparisKalemleri ?? []) as Array<{
    business_id: string;
    price: number;
    quantity: number;
    created_at: string;
  }>;

  // Toplam gelir
  const toplamGelir = kalemler.reduce((s, k) => s + (k.price ?? 0) * (k.quantity ?? 1), 0);
  const kdvTutari = toplamGelir * KDV_ORANI;
  const kdvHaricGelir = toplamGelir - kdvTutari;

  // İşletme bazlı gelir
  const bizGelir: Record<string, number> = {};
  const bizSiparisSayisi: Record<string, number> = {};
  for (const k of kalemler) {
    bizGelir[k.business_id] = (bizGelir[k.business_id] ?? 0) + (k.price ?? 0) * (k.quantity ?? 1);
    bizSiparisSayisi[k.business_id] = (bizSiparisSayisi[k.business_id] ?? 0) + 1;
  }

  // Günlük gelir (son 30 gün)
  const gunlukGelir: Record<string, number> = {};
  for (const k of kalemler) {
    const d = new Date(k.created_at);
    const gun = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth()+1).toString().padStart(2, '0')}`;
    gunlukGelir[gun] = (gunlukGelir[gun] ?? 0) + (k.price ?? 0) * (k.quantity ?? 1);
  }

  const aylar = ayListesi();
  const seciliAyLabel = aylar.find(a => a.key === seciliAy)?.label ?? seciliAy;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Finansal Raporlar"
        description={`Gelir ve vergi özeti — ${seciliAyLabel}`}
        actions={
          <AySeciciForm aylar={aylar} secili={seciliAy} />
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        {businessIds.length === 0 ? (
          <PanelEmptyState
            icon={<TLIcon />}
            title="İşletme bulunamadı"
            description="Finansal raporları görmek için önce onaylı bir işletme gerekir."
          />
        ) : (
          <>
        {/* Özet metrikler */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <MetricCard
            title="Toplam Ciro"
            value={fmtTL(toplamGelir)}
            subtitle={seciliAyLabel}
            icon={<TLIcon />}
          />
          <MetricCard
            title="KDV Hariç"
            value={fmtTL(kdvHaricGelir)}
            subtitle={`%${(KDV_ORANI * 100).toFixed(0)} KDV düşüldü`}
            icon={<ReceiptIcon />}
          />
          <MetricCard
            title="KDV Tutarı"
            value={fmtTL(kdvTutari)}
            subtitle={`%${(KDV_ORANI * 100).toFixed(0)} KDV hesabı`}
            icon={<GovIcon />}
          />
          <MetricCard
            title="Sipariş Kalemi"
            value={kalemler.length.toLocaleString('tr-TR')}
            subtitle={seciliAyLabel}
            icon={<OrderIcon />}
          />
        </div>

        {/* KDV Uyarı Notu */}
        <div className="mt-4 rounded-xl border border-warning/25 bg-warning/[0.06] px-4 py-3">
          <p className="text-xs text-muted">
            <strong>Not:</strong> Buradaki KDV hesabı %{(KDV_ORANI * 100).toFixed(0)} sabit oran üzerinden tahmindir. Gerçek vergi yükümlülüğünüz için muhasebecInize başvurun. Bu rapor resmi fatura yerine geçmez.
          </p>
        </div>

        {/* İşletme bazlı dağılım */}
        {businessIds.length > 0 && (
          <PanelBolumKarti title="İşletme Bazlı Gelir" className="mt-6">
            {Object.keys(bizGelir).length === 0 ? (
              <PanelEmptyState icon={<TLIcon />} title="Bu ay sipariş geliri yok" />
            ) : (
              <div className="divide-y divide-border">
                {businessIds
                  .filter(id => bizGelir[id] !== undefined)
                  .sort((a, b) => (bizGelir[b] ?? 0) - (bizGelir[a] ?? 0))
                  .map(id => {
                    const pct = toplamGelir > 0 ? ((bizGelir[id] ?? 0) / toplamGelir * 100) : 0;
                    return (
                      <div key={id} className="flex items-center gap-4 px-5 py-4">
                        <div className="flex-1 min-w-0">
                          <p className="font-[800] text-textStrong truncate">{bizMap[id] ?? id}</p>
                          <div className="mt-1.5 h-1.5 w-full rounded-full bg-border overflow-hidden">
                            <div
                              className="h-full rounded-full bg-primary"
                              style={{ width: `${pct.toFixed(1)}%` }}
                            />
                          </div>
                        </div>
                        <div className="text-right shrink-0">
                          <p className="font-[900] text-textStrong">{fmtTL(bizGelir[id] ?? 0)}</p>
                          <p className="text-xs text-muted">%{pct.toFixed(0)}</p>
                        </div>
                      </div>
                    );
                  })}
              </div>
            )}
          </PanelBolumKarti>
        )}

        {/* Günlük gelir tablosu */}
        {Object.keys(gunlukGelir).length > 0 && (
          <PanelBolumKarti title="Günlük Gelir" noPadding className="mt-6">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted text-right">Gelir</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted text-right">KDV Hariç</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {Object.entries(gunlukGelir)
                    .sort(([a], [b]) => a.localeCompare(b))
                    .map(([gun, gelir]) => (
                      <tr key={gun} className="hover:bg-cardAlt/50">
                        <td className="px-5 py-3 font-[700] text-textStrong">{gun}</td>
                        <td className="px-5 py-3 font-[900] text-right text-primary">{fmtTL(gelir)}</td>
                        <td className="px-5 py-3 text-right text-muted">{fmtTL(gelir * (1 - KDV_ORANI))}</td>
                      </tr>
                    ))}
                </tbody>
                <tfoot>
                  <tr className="border-t-2 border-border bg-cardAlt">
                    <td className="px-5 py-3 font-[900] text-textStrong">Toplam</td>
                    <td className="px-5 py-3 font-[900] text-right text-primary">{fmtTL(toplamGelir)}</td>
                    <td className="px-5 py-3 font-[900] text-right text-muted">{fmtTL(kdvHaricGelir)}</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </PanelBolumKarti>
        )}

        {/* Muhasebe Entegrasyon Bölümü */}
        <PanelBolumKarti title="Muhasebe Entegrasyonu" className="mt-6">
          <div className="flex flex-col gap-4">
            <p className="text-sm text-muted">
              Finansal raporlarınızı muhasebe yazılımınıza aktarın. Her format ilgili platform için optimize edilmiştir.
            </p>
            <div className="grid gap-3 sm:grid-cols-3">
              {[
                {
                  label: 'Standart CSV',
                  desc: 'Tüm yazılımlar — Excel/Sheets uyumlu',
                  href: `/sunucu/sahip/finansal-csv?ay=${seciliAy}`,
                  color: 'border-green-200 bg-green-50 text-green-800',
                },
                {
                  label: 'Paraşüt Formatı',
                  desc: 'TR muhasebe — Paraşüt doğrudan import',
                  href: `/sunucu/sahip/finansal-csv?ay=${seciliAy}&format=parasut`,
                  color: 'border-blue-200 bg-blue-50 text-blue-800',
                },
                {
                  label: 'Logo Tiger Uyumlu',
                  desc: 'Logo Tiger / LUCA formatında dışa aktar',
                  href: `/sunucu/sahip/finansal-csv?ay=${seciliAy}&format=logo`,
                  color: 'border-purple-200 bg-purple-50 text-purple-800',
                },
              ].map(item => (
                <a
                  key={item.label}
                  href={item.href}
                  className={`flex items-start gap-3 rounded-xl border p-4 transition-opacity hover:opacity-90 ${item.color}`}
                >
                  <DownloadIcon />
                  <div>
                    <p className="font-[800]">{item.label}</p>
                    <p className="text-xs opacity-70">{item.desc}</p>
                  </div>
                </a>
              ))}
            </div>
            <div className="rounded-xl border border-border bg-zinc-50 px-4 py-3 dark:bg-zinc-900/30">
              <p className="text-xs font-[700] text-muted">Hesap Uzlaşması İçin:</p>
              <p className="mt-1 text-xs text-muted">
                Sipariş gelirleri günlük toplamlar halinde aktarılır. KDV ayrıştırması %{(KDV_ORANI * 100).toFixed(0)} sabit oran üzerindendir.
                Gerçek hesap uzlaşması için muhasebecInize danışın.
              </p>
            </div>
          </div>
        </PanelBolumKarti>
          </>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

// ─── Ay seçici (GET form) ─────────────────────────────────────────────────────

function AySeciciForm({ aylar, secili }: { aylar: { key: string; label: string }[]; secili: string }) {
  return (
    <form method="get" className="flex items-center gap-2">
      <select
        name="ay"
        defaultValue={secili}
        className="input-yd rounded-xl px-3 py-2 text-sm"
      >
        {aylar.map(a => (
          <option key={a.key} value={a.key}>{a.label}</option>
        ))}
      </select>
      <button
        type="submit"
        className="min-h-10 rounded-xl border border-border bg-card px-3 text-xs font-[800] text-textStrong hover:bg-bg"
      >
        Uygula
      </button>
    </form>
  );
}

// ─── İkonlar ─────────────────────────────────────────────────────────────────

function TLIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="7" y1="5" x2="17" y2="5" /><line x1="7" y1="12" x2="14" y2="12" /><path d="M9 5v14" /><path d="M14 12v4a2 2 0 0 0 2 2h1" /></svg>;
}
function ReceiptIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 2v20l3-3 3 3 3-3 3 3 3-3V2z" /><line x1="8" y1="10" x2="16" y2="10" /><line x1="8" y1="14" x2="16" y2="14" /></svg>;
}
function GovIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><polyline points="9 22 9 12 15 12 15 22" /></svg>;
}
function OrderIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 11l3 3L22 4" /><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" /></svg>;
}
function DownloadIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>;
}
