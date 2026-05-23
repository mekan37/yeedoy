'use client';

import Link from 'next/link';
import { useEffect, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { usePanelStore } from '@/src/lib/panel-deposu';

export function KullaniciFoteri() {
  const { sidebarCollapsed } = usePanelStore();
  const router = useRouter();
  const [email, setEmail] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    void supabase.auth.getSession().then(({ data }) => {
      setEmail(data.session?.user.email ?? null);
    });
  }, []);

  function signOut() {
    startTransition(async () => {
      const supabase = createSupabaseBrowserClient();
      await supabase.auth.signOut();
      router.push('/giris');
      router.refresh();
    });
  }

  if (sidebarCollapsed) {
    return (
      <div className="flex flex-col items-center gap-1 py-1">
        <Link
          href="/profil"
          title="Profil"
          className="flex h-10 w-10 items-center justify-center rounded-xl text-muted transition-colors hover:bg-textStrong/[0.07] hover:text-textStrong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
        >
          <UserIcon />
        </Link>
        <button
          type="button"
          onClick={signOut}
          disabled={pending}
          title="Çıkış yap"
          className="flex h-10 w-10 items-center justify-center rounded-xl text-muted transition-colors hover:bg-red-50 hover:text-red-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 disabled:opacity-50"
        >
          <LogoutIcon />
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-0.5 py-1">
      {email && (
        <p className="truncate px-3 pb-1 text-[11px] font-[600] text-muted" title={email}>
          {email}
        </p>
      )}
      <Link
        href="/profil"
        className="flex min-h-[40px] items-center gap-3 rounded-xl px-3 text-sm font-[700] text-text transition-colors hover:bg-textStrong/[0.06] hover:text-textStrong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
      >
        <span className="flex h-5 w-5 shrink-0 items-center justify-center text-muted">
          <UserIcon />
        </span>
        Profil
      </Link>
      <button
        type="button"
        onClick={signOut}
        disabled={pending}
        className="flex w-full min-h-[40px] items-center gap-3 rounded-xl px-3 text-sm font-[700] text-text transition-colors hover:bg-red-50 hover:text-red-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 disabled:opacity-50"
      >
        <span className="flex h-5 w-5 shrink-0 items-center justify-center text-muted">
          <LogoutIcon />
        </span>
        {pending ? 'Çıkılıyor…' : 'Çıkış yap'}
      </button>
    </div>
  );
}

function UserIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
      <circle cx="12" cy="7" r="4" />
    </svg>
  );
}

function LogoutIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  );
}
