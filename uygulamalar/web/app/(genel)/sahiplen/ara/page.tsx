import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { IsletmeAramaIstemcisi } from './isletme-arama-istemcisi';

export const metadata: Metadata = {
  title: 'İşletmeni Bul | Yeedoy',
  description: 'Adı, şehir veya ilçesiyle işletmeni bul ve sahiplenmek için başvur.',
  robots: { index: false, follow: false },
};

export default function SahiplenAraPage() {
  return (
    <PublicShell variant="owner">
      <main className="mx-auto max-w-2xl px-4 py-10 sm:px-6">
        <div className="mb-8 text-center">
          <p className="text-xs font-extrabold uppercase tracking-[0.2em] text-primary">
            Adım 1 / 2
          </p>
          <h1 className="mt-2 text-3xl font-black text-textStrong">
            İşletmeni bul
          </h1>
          <p className="mt-2 text-muted">
            Adı, şehir veya ilçesiyle ara. Sonuçlardan işletmeni seç.
          </p>
        </div>
        <IsletmeAramaIstemcisi />
      </main>
    </PublicShell>
  );
}
