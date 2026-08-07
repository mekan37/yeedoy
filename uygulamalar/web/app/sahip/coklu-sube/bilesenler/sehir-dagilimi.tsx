import Link from 'next/link';
import { cityDistribution, type CokluSubeBranch } from '../coklu-sube-yardimcilari';

function PinIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M12 21s-7-6.5-7-11a7 7 0 0 1 14 0c0 4.5-7 11-7 11Z" />
      <circle cx="12" cy="10" r="2.5" />
    </svg>
  );
}

export function SehirDagilimi({ branches }: { branches: CokluSubeBranch[] }) {
  const distribution = cityDistribution(branches);

  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-3 text-sm font-black text-textStrong">Şehre Göre Dağılım</h3>
      {distribution.length === 0 ? (
        <p className="text-xs text-muted">Henüz şube yok.</p>
      ) : (
        <div className="flex flex-col gap-2">
          {distribution.map((item) => (
            <div key={item.city} className="flex items-center justify-between gap-2 text-sm">
              <span className="flex items-center gap-2 text-textStrong">
                <PinIcon />
                {item.city}
              </span>
              <span className="rounded-full bg-bg px-2 py-0.5 text-xs font-bold text-muted">{item.count} şube</span>
            </div>
          ))}
        </div>
      )}
      <Link
        href="/kesif/harita"
        target="_blank"
        rel="noopener noreferrer"
        className="mt-3 block rounded-xl border border-border px-3 py-2 text-center text-xs font-bold text-textStrong hover:bg-bg"
      >
        Haritada Görüntüle
      </Link>
    </div>
  );
}
