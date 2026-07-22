import type { Metadata } from 'next';
import Link from 'next/link';
import { Suspense } from 'react';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { EnIyilerCanli } from '@/src/ui/acik/en-iyiler-canli';

export const metadata: Metadata = {
  title: 'En İyi İşletmeler | Yeedoy',
  description: "Kullanıcıların değerlendirmelerine göre Yeedoy'un en iyi mekanları",
};

function EnIyilerSkelton() {
  return (
    <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
      <div className="h-80 w-full animate-pulse rounded-2xl bg-border lg:w-56 lg:shrink-0" />
      <div className="flex-1">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="overflow-hidden rounded-[20px] border border-border bg-card">
              <div className="w-full animate-pulse bg-border" style={{ aspectRatio: '4/3' }} />
              <div className="space-y-2 p-3">
                <div className="h-4 w-3/4 animate-pulse rounded bg-border" />
                <div className="h-3 w-1/2 animate-pulse rounded bg-border" />
                <div className="mt-3 h-8 animate-pulse rounded-lg bg-border" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default function EnIyilerPage() {
  return (
    <PublicShell>
      <main className="min-h-screen bg-bg">
        <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">

          {/* Ekmek kırıntısı */}
          <nav className="mb-5 flex items-center gap-1.5 text-xs font-[700] text-muted" aria-label="Konum">
            <Link href="/" className="hover:text-primary">Ana Sayfa</Link>
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
              <path d="M9 18l6-6-6-6" />
            </svg>
            <span className="text-textStrong">En İyiler</span>
          </nav>

          {/* Başlık */}
          <div className="mb-6">
            <h1 className="text-2xl font-[900] text-textStrong sm:text-3xl">
              En İyi İşletmeler
            </h1>
            <p className="mt-1 text-sm font-[700] text-muted">
              Kullanıcıların değerlendirmelerine göre en iyi mekanlar — anlık filtreleme
            </p>
          </div>

          {/* Canlı filtreleme */}
          <Suspense fallback={<EnIyilerSkelton />}>
            <EnIyilerCanli />
          </Suspense>

        </div>

        {/* Alt güven şeridi */}
        <div className="mt-12 border-t border-border bg-card">
          <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
            <div className="grid grid-cols-2 gap-6 sm:grid-cols-4">
              {[
                {
                  icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>,
                  title: 'Gerçek Yorumlar',
                  desc: 'Tüm puanlar gerçek kullanıcı yorumlarına göre',
                },
                {
                  icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>,
                  title: 'Güvenilir Mekanlar',
                  desc: 'Onaylı işletmeler ve kaliteli hizmet',
                },
                {
                  icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="12" cy="8" r="6" /><path d="M15.477 12.89 17 22l-5-3-5 3 1.523-9.11" /></svg>,
                  title: 'En İyi Deneyim',
                  desc: 'Yüksek puanlı mekanları keşfedin',
                },
                {
                  icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="12" cy="12" r="10" /><path d="M15 9h-3a2 2 0 0 0 0 4h0a2 2 0 0 1 0 4H9" /><line x1="12" y1="7" x2="12" y2="9" /><line x1="12" y1="17" x2="12" y2="19" /></svg>,
                  title: 'Özel Fırsatlar',
                  desc: 'En iyi mekanlarda özel indirimler',
                },
              ].map((item) => (
                <div key={item.title} className="flex items-start gap-3">
                  <div className="mt-0.5 shrink-0 text-primary">{item.icon}</div>
                  <div>
                    <p className="text-sm font-[900] text-textStrong">{item.title}</p>
                    <p className="mt-0.5 text-xs font-[700] leading-5 text-muted">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

      </main>
    </PublicShell>
  );
}
