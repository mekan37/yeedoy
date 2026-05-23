import type { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = { title: 'Taste Twin | Yeedoy', robots: { index: false, follow: false } };

export default function TasteTwinPage() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/profile" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted transition-colors hover:text-primary">
          <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current" aria-hidden="true"><path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/></svg>
          Profile Dön
        </Link>
        <div className="rounded-[20px] border border-border bg-card p-8 text-center shadow-yd2">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-[var(--yd-color-primary-soft)]">
            <svg viewBox="0 0 24 24" className="h-7 w-7 text-primary" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" />
              <path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
            </svg>
          </div>
          <h1 className="mb-2 text-2xl font-[900] text-textStrong">Taste Twin</h1>
          <p className="mb-4 text-sm leading-relaxed text-muted">Benzer damak zevkine sahip gurmeleri keşfedin ve onların favori mekanlarını görün.</p>
          <span className="inline-flex rounded-full bg-amber-50 px-4 py-2 text-sm font-[700] text-amber-700">Yakında</span>
          <p className="mt-6 text-sm text-muted">Bu özellik için daha fazla yorum ve değerlendirme verisi toplanıyor.</p>
          <Link
            href="/discover"
            className="mt-6 inline-flex min-h-[44px] items-center rounded-2xl px-5 text-sm font-[800] text-white transition-all duration-[180ms] hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
            style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}
          >
            Keşfetmeye Devam Et
          </Link>
        </div>
      </div>
    </main>
  );
}
