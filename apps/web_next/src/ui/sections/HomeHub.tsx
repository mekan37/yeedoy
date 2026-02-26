'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import type { ReactElement } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/supabaseClient';

type HubState =
  | { loading: true; email: null; isAdmin: false }
  | { loading: false; email: string; isAdmin: boolean };

type HubCard = {
  key: string;
  title: string;
  description: string;
  href: string;
  icon: (className?: string) => ReactElement;
  tone: string;
};

export function HomeHub() {
  const router = useRouter();
  const [state, setState] = useState<HubState>({
    loading: true,
    email: null,
    isAdmin: false,
  });

  useEffect(() => {
    let mounted = true;

    async function bootstrap() {
      const supabase = createSupabaseBrowserClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();

      if (!mounted) return;
      if (!user) {
        router.replace('/login');
        return;
      }

      const { data: adminRow } = await supabase
        .from('admin_users')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();

      const claimAdmin = Boolean(user.app_metadata?.is_admin);
      const tableAdmin = Boolean(adminRow?.user_id);
      const isAdmin = claimAdmin || tableAdmin;

      setState({
        loading: false,
        email: user.email ?? 'Kullanıcı',
        isAdmin,
      });
    }

    void bootstrap();
    return () => {
      mounted = false;
    };
  }, [router]);

  const cards = useMemo<HubCard[]>(
    () =>
      [
        {
          key: 'owner',
          title: 'İşletme Paneli',
          description: 'Menü, içerik ve işletme akışlarını tek panelden yönet.',
          href: '/owner',
          icon: BuildingIcon,
          tone: 'border-primary/20 bg-card',
        },
        state.isAdmin
          ? {
              key: 'admin',
              title: 'Admin Paneli',
              description: 'Operasyon, moderasyon ve sistem yönetimi araçları.',
              href: '/admin',
              icon: ShieldIcon,
              tone: 'border-info/25 bg-card',
            }
          : null,
        {
          key: 'builder',
          title: 'Dijital Menü Oluşturucu',
          description: 'Standart alanlarla hızlı menü üret ve yayına al.',
          href: '/menu-builder',
          icon: SparkIcon,
          tone: 'border-success/25 bg-card',
        },
      ].filter(Boolean) as HubCard[],
    [state.isAdmin],
  );

  if (state.loading) {
    return (
      <main className="min-h-screen bg-bg">
        <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
          <div className="h-8 w-56 animate-pulse rounded bg-slate/10" />
          <div className="mt-8 grid gap-4 md:grid-cols-3">
            <div className="h-56 animate-pulse rounded-3xl border border-border bg-card" />
            <div className="h-56 animate-pulse rounded-3xl border border-border bg-card" />
            <div className="h-56 animate-pulse rounded-3xl border border-border bg-card" />
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-bg">
      <section className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
        <header className="rounded-3xl border border-border bg-card p-8 shadow-sm">
          <p className="text-sm font-semibold uppercase tracking-wide text-muted">MenüBak Hub</p>
          <h1 className="mt-2 text-3xl font-black text-primary sm:text-4xl">Hoş geldin</h1>
          <p className="mt-2 text-base text-text">{state.email}</p>
          <p className="mt-4 max-w-2xl text-sm text-muted">
            İhtiyacın olan panele doğrudan geç. Tüm girişler tek veri modeline bağlı menü alanlarını kullanır.
          </p>
        </header>

        <div className="mt-6 grid gap-4 md:grid-cols-3">
          {cards.map((card) => (
            <Link
              key={card.key}
              href={card.href}
              className={`group rounded-3xl border p-6 transition duration-200 hover:-translate-y-0.5 hover:border-primary/50 hover:shadow-xl ${card.tone}`}
            >
              <div className="inline-flex rounded-xl border border-border bg-bg p-2">
                {card.icon('h-6 w-6 text-primary')}
              </div>
              <h2 className="mt-5 text-xl font-extrabold text-text">{card.title}</h2>
              <p className="mt-2 text-sm leading-6 text-muted">{card.description}</p>
              <span className="mt-6 inline-flex items-center text-sm font-semibold text-primary">
                Panele Git
                <span className="ml-2 transition group-hover:translate-x-1">{'>'}</span>
              </span>
            </Link>
          ))}
        </div>
      </section>
    </main>
  );
}

function BuildingIcon(className = 'h-6 w-6') {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M4 20V5.5L12 3l8 2.5V20M8 20v-3m8 3v-3M8 8h.01M8 12h.01M12 8h.01M12 12h.01M16 8h.01M16 12h.01" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  );
}

function ShieldIcon(className = 'h-6 w-6') {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M12 3l7 3v5c0 4.8-2.8 8-7 10-4.2-2-7-5.2-7-10V6l7-3Z" stroke="currentColor" strokeWidth="1.7" />
      <path d="m9 12 2 2 4-4" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function SparkIcon(className = 'h-6 w-6') {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M12 3v4m0 10v4M5 12H1m22 0h-4M6.2 6.2 3.4 3.4m17.2 17.2-2.8-2.8M17.8 6.2l2.8-2.8M3.4 20.6l2.8-2.8" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      <circle cx="12" cy="12" r="3.5" stroke="currentColor" strokeWidth="1.7" />
    </svg>
  );
}
