import Link from 'next/link';
import { FAQ_ITEMS } from '../destek-yardimcilari';

export function SssWidget({ filter = '' }: { filter?: string }) {
  const q = filter.trim().toLocaleLowerCase('tr-TR');
  const items = q
    ? FAQ_ITEMS.filter((item) => item.q.toLocaleLowerCase('tr-TR').includes(q) || item.a.toLocaleLowerCase('tr-TR').includes(q))
    : FAQ_ITEMS;

  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <div className="mb-3 flex items-center justify-between">
        <h3 className="text-sm font-black text-textStrong">Sıkça Sorulan Sorular</h3>
        <Link href="/destek" className="shrink-0 text-xs font-extrabold text-primary hover:underline">
          Tümünü Görüntüle
        </Link>
      </div>
      {items.length === 0 ? (
        <p className="text-xs text-muted">&quot;{filter}&quot; ile eşleşen soru bulunamadı.</p>
      ) : (
        <div className="flex flex-col divide-y divide-border">
          {items.map((item) => (
            <details key={item.q} className="group py-2.5 first:pt-0 last:pb-0">
              <summary className="flex cursor-pointer list-none items-center justify-between gap-2 text-xs font-bold text-textStrong [&::-webkit-details-marker]:hidden">
                <span>{item.q}</span>
                <span className="shrink-0 text-muted transition-transform group-open:rotate-180">⌄</span>
              </summary>
              <p className="mt-2 text-xs leading-relaxed text-muted">{item.a}</p>
            </details>
          ))}
        </div>
      )}
    </div>
  );
}
