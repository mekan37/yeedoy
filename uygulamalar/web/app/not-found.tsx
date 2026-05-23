import Link from 'next/link';

export default function NotFoundPage() {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-4xl items-center px-4 py-12 sm:px-6">
      <section className="w-full overflow-hidden rounded-[32px] border border-border bg-card shadow-yd2">
        <div className="bg-[radial-gradient(circle_at_top_left,_rgba(255,255,255,0.28),_transparent_36%),linear-gradient(135deg,_rgb(var(--yd-color-primary-rgb)),_rgb(var(--yd-color-primary-strong-rgb)))] px-8 py-10 text-white">
          <p className="text-xs font-black uppercase tracking-[0.24em] text-white/75">404</p>
          <h1 className="mt-3 text-3xl font-black sm:text-4xl">Menu not found</h1>
          <p className="mt-3 max-w-2xl text-sm leading-7 text-white/84">
            This business does not have a published public menu, or the route key is no longer valid.
          </p>
        </div>
        <div className="space-y-5 px-8 py-8">
          <div className="rounded-[24px] border border-border bg-bg p-5">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-muted">What to check</p>
            <p className="mt-2 text-sm leading-7 text-text">
              Open the QR again, verify the public menu slug or QR link, or return to the public menu landing page.
            </p>
          </div>
          <Link
            href="/"
            className="inline-flex rounded-2xl bg-primary px-5 py-3 text-sm font-black text-white"
          >
            Home
          </Link>
        </div>
      </section>
    </main>
  );
}
