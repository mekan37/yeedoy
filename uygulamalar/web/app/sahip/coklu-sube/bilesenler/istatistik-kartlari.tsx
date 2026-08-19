import type { CokluSubeOverview } from '../coklu-sube-yardimcilari';

const TONE_CLASSES = {
  red: 'bg-red-50 text-red-600',
  green: 'bg-emerald-50 text-emerald-600',
  orange: 'bg-amber-50 text-amber-600',
  blue: 'bg-blue-50 text-blue-600',
} as const;

export function IstatistikKartlari({ overview }: { overview: CokluSubeOverview }) {
  const cityCount = new Set(overview.branches.map((b) => b.city ?? 'Bilinmiyor')).size;

  const kartlar = [
    {
      label: 'Toplam Şube',
      value: String(overview.branches.length),
      subtitle: `${cityCount} şehirde`,
      tone: 'red' as const,
      icon: <BranchIcon />,
    },
    {
      label: 'Toplam Görüntülenme',
      value: overview.total_views.toLocaleString('tr-TR'),
      subtitle: null,
      tone: 'green' as const,
      icon: <EyeIcon />,
    },
    {
      label: 'Toplam Profil Ziyareti',
      value: overview.total_page_views.toLocaleString('tr-TR'),
      subtitle: null,
      tone: 'orange' as const,
      icon: <UserIcon />,
    },
    {
      label: 'Toplam Rezervasyon',
      value: overview.total_reservations.toLocaleString('tr-TR'),
      subtitle: null,
      tone: 'blue' as const,
      icon: <CalendarIcon />,
    },
  ];

  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
      {kartlar.map((kart) => (
        <div key={kart.label} className="rounded-2xl border border-border bg-card p-4 shadow-xs">
          <div className={`mb-2 flex h-9 w-9 items-center justify-center rounded-xl ${TONE_CLASSES[kart.tone]}`}>
            {kart.icon}
          </div>
          <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{kart.label}</p>
          <p className="mt-0.5 text-2xl font-black text-textStrong">{kart.value}</p>
          {kart.subtitle && <p className="mt-0.5 text-[11px] text-muted">{kart.subtitle}</p>}
        </div>
      ))}
    </div>
  );
}

function BranchIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 3v12" /><circle cx="18" cy="6" r="3" /><circle cx="6" cy="18" r="3" /><path d="M18 9a9 9 0 0 1-9 9" /></svg>;
}
function EyeIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>;
}
function UserIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>;
}
function CalendarIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" /></svg>;
}
