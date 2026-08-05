import { MenuStats } from '../menu-duzenleyici-yardimcilari';

function formatTarih(iso: string | null): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('tr-TR', { day: '2-digit', month: 'short', year: 'numeric' });
}

export function IstatistikKartlari({ stats }: { stats: MenuStats }) {
  const kartlar = [
    { label: 'Toplam Kategori', value: String(stats.toplamKategori), icon: <KategoriIcon /> },
    { label: 'Toplam Ürün', value: String(stats.toplamUrun), icon: <UrunIcon /> },
    { label: 'Aktif Ürün', value: String(stats.aktifUrun), icon: <AktifIcon /> },
    { label: 'Pasif Ürün', value: String(stats.pasifUrun), icon: <PasifIcon /> },
    { label: 'Son Güncelleme', value: formatTarih(stats.sonGuncelleme), icon: <SaatIcon /> },
  ];

  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
      {kartlar.map((kart) => (
        <div key={kart.label} className="rounded-2xl border border-border bg-card p-4 shadow-xs">
          <div className="mb-2 flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
            {kart.icon}
          </div>
          <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{kart.label}</p>
          <p className="mt-0.5 text-lg font-black text-textStrong">{kart.value}</p>
        </div>
      ))}
    </div>
  );
}

function KategoriIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>;
}
function UrunIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M20 7L12 3 4 7v10l8 4 8-4V7z"/><path d="M4 7l8 4 8-4M12 11v10"/></svg>;
}
function AktifIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M20 6L9 17l-5-5"/></svg>;
}
function PasifIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="8" y1="12" x2="16" y2="12"/></svg>;
}
function SaatIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>;
}
