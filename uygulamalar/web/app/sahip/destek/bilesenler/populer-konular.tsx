import Link from 'next/link';
import { POPULER_KONULAR } from '../destek-yardimcilari';

export function PopulerKonular() {
  return (
    <div>
      <h2 className="mb-3 text-sm font-black text-textStrong">Popüler Konular</h2>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        {POPULER_KONULAR.map((konu) => (
          <Link
            key={konu.href}
            href={konu.href}
            className="flex flex-col gap-2 rounded-2xl border border-border bg-card p-4 transition-colors hover:border-primary/30"
          >
            <p className="text-sm font-bold text-textStrong">{konu.title}</p>
            <p className="text-xs text-muted">{konu.description}</p>
          </Link>
        ))}
      </div>
    </div>
  );
}
