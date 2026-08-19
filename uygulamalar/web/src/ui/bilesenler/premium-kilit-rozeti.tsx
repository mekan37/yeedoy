import Link from 'next/link';

export function PremiumKilitRozeti({ label = 'Premium gerekli' }: { label?: string }) {
  return (
    <Link
      href="/sahip/premium"
      className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-wide text-amber-700 transition-colors hover:bg-amber-100"
    >
      <CrownIcon /> {label}
    </Link>
  );
}

function CrownIcon() {
  return (
    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="m2 20 2-11 5 5 3-8 3 8 5-5 2 11Z" />
    </svg>
  );
}
