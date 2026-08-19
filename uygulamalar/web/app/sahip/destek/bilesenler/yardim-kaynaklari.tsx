import Link from 'next/link';

const KAYNAKLAR = [
  { title: 'Başlangıç Rehberi', description: 'Panelinizi adım adım kurun.', href: '/sahip/baslangic' },
  { title: 'Yardım Merkezi', description: 'Tüm sık sorulan sorular ve kılavuzlar.', href: '/destek' },
];

export function YardimKaynaklari() {
  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-3 text-sm font-black text-textStrong">Yardım Kaynakları</h3>
      <div className="flex flex-col gap-1">
        {KAYNAKLAR.map((k) => (
          <Link
            key={k.href}
            href={k.href}
            className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 transition-colors hover:bg-black/4"
          >
            <div className="min-w-0">
              <p className="text-xs font-extrabold text-textStrong">{k.title}</p>
              <p className="text-[11px] text-muted">{k.description}</p>
            </div>
            <ExternalLinkIcon />
          </Link>
        ))}
      </div>
    </div>
  );
}

function ExternalLinkIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
      <polyline points="15 3 21 3 21 9" />
      <line x1="10" y1="14" x2="21" y2="3" />
    </svg>
  );
}
