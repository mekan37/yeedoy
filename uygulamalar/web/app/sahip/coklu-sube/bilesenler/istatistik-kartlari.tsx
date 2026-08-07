import type { CokluSubeOverview } from '../coklu-sube-yardimcilari';

export function IstatistikKartlari({ overview }: { overview: CokluSubeOverview }) {
  const cityCount = new Set(overview.branches.map((b) => b.city ?? 'Bilinmiyor')).size;

  const kartlar = [
    { label: 'Toplam Şube', value: String(overview.branches.length) },
    { label: 'Toplam Görüntülenme', value: overview.total_views.toLocaleString('tr-TR') },
    { label: 'Toplam Rezervasyon', value: overview.total_reservations.toLocaleString('tr-TR') },
    { label: 'Şehir Sayısı', value: String(cityCount) },
  ];

  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
      {kartlar.map((kart) => (
        <div key={kart.label} className="rounded-2xl border border-border bg-card p-4">
          <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{kart.label}</p>
          <p className="mt-1 text-2xl font-black text-textStrong">{kart.value}</p>
        </div>
      ))}
    </div>
  );
}
