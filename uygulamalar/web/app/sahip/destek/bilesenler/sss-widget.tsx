import { FAQ_ITEMS } from '../destek-yardimcilari';

export function SssWidget() {
  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-3 text-sm font-black text-textStrong">Sıkça Sorulan Sorular</h3>
      <div className="flex flex-col divide-y divide-border">
        {FAQ_ITEMS.map((item) => (
          <details key={item.q} className="group py-2.5 first:pt-0 last:pb-0">
            <summary className="flex cursor-pointer list-none items-center justify-between gap-2 text-xs font-bold text-textStrong [&::-webkit-details-marker]:hidden">
              <span>{item.q}</span>
              <span className="shrink-0 text-muted transition-transform group-open:rotate-180">⌄</span>
            </summary>
            <p className="mt-2 text-xs leading-relaxed text-muted">{item.a}</p>
          </details>
        ))}
      </div>
    </div>
  );
}
