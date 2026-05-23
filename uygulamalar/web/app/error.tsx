'use client';

import { useEffect } from 'react';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('[web_next] global error', error);
  }, [error]);

  return (
    <html lang="tr">
      <body className="bg-bg text-text">
        <main className="mx-auto flex min-h-screen w-full max-w-4xl items-center px-4 py-12 sm:px-6">
          <section className="w-full overflow-hidden rounded-[32px] border border-border bg-card shadow-yd2">
            <div className="bg-[radial-gradient(circle_at_top_left,_rgba(255,255,255,0.28),_transparent_36%),linear-gradient(135deg,_rgb(var(--yd-color-primary-rgb)),_rgb(var(--yd-color-primary-strong-rgb)))] px-8 py-10 text-white">
              <p className="text-xs font-black uppercase tracking-[0.24em] text-white/75">Runtime error</p>
              <h1 className="mt-3 text-3xl font-black sm:text-4xl">Something went wrong</h1>
              <p className="mt-3 max-w-2xl text-sm leading-7 text-white/84">
                The public menu could not be rendered. Retry once; if the error persists, inspect the server logs.
              </p>
            </div>
            <div className="space-y-5 px-8 py-8">
              <div className="rounded-[24px] border border-border bg-bg p-5">
                <p className="text-xs font-black uppercase tracking-[0.2em] text-muted">Digest</p>
                <p className="mt-2 break-all text-sm leading-7 text-text">{error.digest ?? 'n/a'}</p>
              </div>
              <button
                type="button"
                onClick={() => reset()}
                className="rounded-2xl bg-primary px-5 py-3 text-sm font-black text-white"
              >
                Retry
              </button>
            </div>
          </section>
        </main>
      </body>
    </html>
  );
}
