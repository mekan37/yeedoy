import Link from 'next/link';

type Props = {
  title: string;
  message: string;
  hint?: string;
  backHref?: string;
  backLabel?: string;
};

/**
 * Next.js 16.2.11'de bir loading.tsx'in oluşturduğu Suspense sınırı içinde
 * fırlatılan notFound() client'a hiç swap edilmiyor (doğru HTML stream'de var
 * ama tarayıcı sonsuza kadar iskelet ekranında kalıyor — canlıda doğrulandı,
 * bkz. app/(genel)/m/[slug]/page.tsx). Kendi loading.tsx'i olan her rota bu
 * bileşeni notFound() yerine doğrudan render etmeli.
 */
export function NotFoundFallback({
  title,
  message,
  hint,
  backHref = '/',
  backLabel = 'Ana sayfa',
}: Props) {
  return (
    <main className="mx-auto flex min-h-[60vh] w-full max-w-4xl items-center px-4 py-12 sm:px-6">
      <section className="w-full overflow-hidden rounded-[32px] border border-border bg-card shadow-yd2">
        <div className="bg-[radial-gradient(circle_at_top_left,rgba(255,255,255,0.28),transparent_36%),linear-gradient(135deg,rgb(var(--yd-color-primary-rgb)),rgb(var(--yd-color-primary-strong-rgb)))] px-8 py-10 text-white">
          <p className="text-xs font-black uppercase tracking-[0.24em] text-white/75">404</p>
          <h1 className="mt-3 text-3xl font-black sm:text-4xl">{title}</h1>
          <p className="mt-3 max-w-2xl text-sm leading-7 text-white/84">{message}</p>
        </div>
        <div className="space-y-5 px-8 py-8">
          {hint ? (
            <div className="rounded-[24px] border border-border bg-bg p-5">
              <p className="text-xs font-black uppercase tracking-[0.2em] text-muted">Neye bakılmalı</p>
              <p className="mt-2 text-sm leading-7 text-text">{hint}</p>
            </div>
          ) : null}
          <Link
            href={backHref}
            className="inline-flex rounded-2xl bg-primary px-5 py-3 text-sm font-black text-white transition-opacity hover:opacity-90"
          >
            {backLabel}
          </Link>
        </div>
      </section>
    </main>
  );
}
