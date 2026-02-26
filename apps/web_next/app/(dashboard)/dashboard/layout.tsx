import Link from 'next/link';
import type { ReactNode } from 'react';
import { requireUser } from '@/src/lib/auth';

export default async function DashboardLayout({ children }: { children: ReactNode }) {
  const user = await requireUser();

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="sticky top-0 z-20 border-b border-slate-200/80 bg-white/90 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4">
          <Link href="/dashboard" className="text-lg font-extrabold tracking-tight text-slate-900">
            Yeedoy Isletme Paneli
          </Link>
          <nav className="flex items-center gap-2 text-sm">
            <Link href="/dashboard" className="rounded-lg px-3 py-2 text-slate-700 hover:bg-slate-100">
              Genel Bakis
            </Link>
            <Link href="/dashboard/businesses" className="rounded-lg px-3 py-2 text-slate-700 hover:bg-slate-100">
              Isletmeler
            </Link>
            <span className="hidden rounded-full bg-slate-100 px-3 py-1 text-xs text-slate-500 sm:inline">
              {user.email}
            </span>
          </nav>
        </div>
      </header>

      <main className="mx-auto w-full max-w-6xl px-4 py-6">{children}</main>
    </div>
  );
}
