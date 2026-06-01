'use client';

import dynamic from 'next/dynamic';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';

// dynamic() with ssr:false must live in a Client Component.
// This thin wrapper is imported by the Server Component page.
const HaritaIstemcisi = dynamic(
  () => import('@/src/ui/acik/harita-istemcisi').then((m) => ({ default: m.HaritaIstemcisi })),
  {
    ssr: false,
    loading: () => (
      <div className="flex h-full w-full items-center justify-center bg-slate-50">
        <span className="text-sm text-muted">Harita yükleniyor…</span>
      </div>
    ),
  },
);

export function HaritaSarmalayici({ businesses }: { businesses: HaritaIsletme[] }) {
  return <HaritaIstemcisi businesses={businesses} />;
}
