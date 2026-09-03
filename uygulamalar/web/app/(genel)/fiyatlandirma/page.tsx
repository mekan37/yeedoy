import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowRight } from 'lucide-react';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { FiyatlandirmaIstemcisi } from './fiyatlandirma-istemcisi';

export const metadata: Metadata = {
  title: 'Fiyatlandırma | Yeedoy İşletme Paneli',
  description:
    'Yeedoy İşletme Paneli ücretsiz kademeyle başlar. Menü limitini kaldırmak, AI otomasyonlarını açmak ya da haritada öne çıkmak için Başlangıç, Standart ve Pro kademelerini karşılaştırın.',
  alternates: { canonical: '/fiyatlandirma' },
  robots: { index: true, follow: true },
};

export default function FiyatlandirmaPage() {
  return (
    <PublicShell variant="owner">
      <main className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
        {/* Ekmek kırıntısı */}
        <nav className="mb-6 flex items-center gap-1.5 text-xs font-bold text-muted" aria-label="Konum">
          <Link href="/sahip" className="hover:text-primary">İşletme Paneli</Link>
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
            <path d="M9 18l6-6-6-6" />
          </svg>
          <span className="text-textStrong">Fiyatlandırma</span>
        </nav>

        <FiyatlandirmaIstemcisi />

        {/* Alt CTA */}
        <div className="mt-12 flex flex-col items-center gap-3 rounded-[24px] border border-border bg-cardAlt p-8 text-center">
          <h2 className="text-xl font-black text-textStrong">Henüz karar vermediniz mi?</h2>
          <p className="max-w-md text-sm text-muted">
            Sorun değil — ücretsiz kademeyle kaydolun, işletmenizi ekleyin, istediğiniz zaman panelinizden yükseltme
            talebi oluşturun.
          </p>
          <Link
            href="/giris?tab=kayit"
            className="mt-2 flex h-12 items-center gap-2 rounded-xl bg-primary px-8 text-sm font-extrabold text-white shadow-yd1 transition hover:brightness-105"
          >
            Ücretsiz Başla
            <ArrowRight size={16} aria-hidden="true" />
          </Link>
          <Link href="/sahip" className="mt-1 text-xs font-bold text-muted hover:text-primary">
            ← İşletme Paneli hakkında daha fazla bilgi
          </Link>
        </div>
      </main>
    </PublicShell>
  );
}
