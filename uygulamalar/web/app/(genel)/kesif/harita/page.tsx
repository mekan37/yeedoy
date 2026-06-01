import type { Metadata } from 'next';
import Link from 'next/link';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';
import { getMapBusinesses } from '@/src/lib/veri/harita-okuma';
import { HaritaSarmalayici } from './harita-sarmalayici';

export const revalidate = 120;

export const metadata: Metadata = {
  title: 'Harita | Keşfet | Yeedoy',
  description: 'Türkiye genelinde restoranları, kafeleri ve işletmeleri harita üzerinde keşfedin.',
};

export default async function HaritaPage() {
  const businesses = await getMapBusinesses(120);

  return (
    <PublicShell footer={false}>
      <main className="flex flex-col" style={{ height: 'calc(100vh - 64px)' }}>
        {/* View toggle bar */}
        <div className="sticky top-16 z-30 border-b border-border bg-card shadow-sm">
          <Container>
            <div className="flex min-h-[52px] items-center gap-2">
              <Link
                href="/kesif"
                className="inline-flex min-h-[36px] items-center rounded-xl px-4 text-sm font-[900] text-muted hover:bg-cardAlt"
              >
                Liste
              </Link>
              <span
                className="inline-flex min-h-[36px] items-center rounded-xl bg-primary px-4 text-sm font-[900] text-white"
                aria-current="page"
              >
                Harita
              </span>
              <span className="ml-auto text-xs text-muted">{businesses.length} işletme</span>
            </div>
          </Container>
        </div>

        {/* Full-height map */}
        <div className="relative flex-1">
          <HaritaSarmalayici businesses={businesses} />

          {/* Legend overlay */}
          <div className="pointer-events-none absolute bottom-4 left-4 z-10 rounded-2xl border border-border bg-card/95 px-4 py-3 backdrop-blur">
            <p className="text-xs font-[900] text-textStrong">OpenStreetMap</p>
            <p className="text-[11px] text-muted">Pin&apos;e tıkla → işletme detayı</p>
          </div>
        </div>
      </main>
    </PublicShell>
  );
}
