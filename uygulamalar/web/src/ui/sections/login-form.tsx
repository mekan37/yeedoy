'use client';

import { useEffect, useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/supabase/client';

type Props = {
  redirectTo: string;
  panelLoginUrl: string | null;
};

export function LoginForm({ redirectTo, panelLoginUrl }: Props) {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    let ignore = false;

    async function syncExistingSession() {
      const supabase = createSupabaseBrowserClient();
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (ignore || !session) return;
      router.replace(redirectTo);
      router.refresh();
    }

    void syncExistingSession();

    return () => {
      ignore = true;
    };
  }, [redirectTo, router]);

  return (
    <section className="w-full rounded-[32px] border border-border bg-card p-8 shadow-yd2">
      <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">Owner login required</p>
      <h1 className="mt-3 text-3xl font-black text-textStrong">Sign in to open QR generation</h1>
      <p className="mt-3 text-sm leading-7 text-muted">
        QR generation is restricted to authenticated owner or admin users. If you came from the panel, the session
        handoff should sign you in automatically.
      </p>

      <form
        className="mt-6"
        onSubmit={(event) => {
          event.preventDefault();
          setError('');

          startTransition(async () => {
            const supabase = createSupabaseBrowserClient();
            const { error: signInError } = await supabase.auth.signInWithPassword({
              email: email.trim(),
              password,
            });

            if (signInError) {
              setError(signInError.message);
              return;
            }

            router.replace(redirectTo);
            router.refresh();
          });
        }}
      >
        <label className="block">
          <span className="mb-2 block text-xs font-black uppercase tracking-[0.2em] text-muted">Email</span>
          <input
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className="h-11 w-full rounded-2xl border border-border bg-bg px-4 text-sm leading-5 text-text outline-none transition focus:border-primary"
            autoComplete="email"
            required
          />
        </label>

        <label className="mt-4 block">
          <span className="mb-2 block text-xs font-black uppercase tracking-[0.2em] text-muted">Password</span>
          <input
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className="h-11 w-full rounded-2xl border border-border bg-bg px-4 text-sm leading-5 text-text outline-none transition focus:border-primary"
            autoComplete="current-password"
            required
          />
        </label>

        {error ? <p className="mt-4 text-sm font-semibold text-primary">{error}</p> : null}

        <div className="mt-6 grid gap-3">
          <button
            type="submit"
            disabled={isPending}
            className="inline-flex w-full touch-manipulation items-center justify-center rounded-[20px] bg-primary px-5 py-4 text-sm font-black leading-none text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/35 disabled:opacity-60"
            style={{ minHeight: 48, minWidth: 48 }}
          >
            {isPending ? 'Signing in...' : 'Sign in'}
          </button>
          {panelLoginUrl ? (
            <Link
              href={panelLoginUrl}
              className="inline-flex w-full touch-manipulation items-center justify-center rounded-[20px] border border-border px-5 py-4 text-sm font-black leading-none text-textStrong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/35"
              style={{ minHeight: 48, minWidth: 48 }}
            >
              Open panel login
            </Link>
          ) : null}
        </div>
      </form>
    </section>
  );
}
