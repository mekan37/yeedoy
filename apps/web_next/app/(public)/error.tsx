'use client';

export default function PublicMenuError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-4xl items-center px-4 py-12 sm:px-6">
      <section className="w-full overflow-hidden rounded-[32px] border border-border bg-card shadow-yd2">
        <div className="bg-[radial-gradient(circle_at_top_left,_rgba(255,255,255,0.28),_transparent_36%),linear-gradient(135deg,_rgb(var(--yd-color-primary-rgb)),_rgb(var(--yd-color-primary-strong-rgb)))] px-8 py-10 text-white">
          <p className="text-xs font-black uppercase tracking-[0.24em] text-white/75">
            Menü yüklenemedi
          </p>
          <h1 className="mt-3 text-3xl font-black sm:text-4xl">Bir sorun oluştu</h1>
          <p className="mt-3 max-w-2xl text-sm leading-7 text-white/84">
            Menü sayfası yüklenirken bir hata oluştu. Lütfen tekrar deneyin.
          </p>
        </div>
        <div className="space-y-5 px-8 py-8">
          {error.digest ? (
            <div className="rounded-[24px] border border-border bg-bg p-5">
              <p className="text-xs font-black uppercase tracking-[0.2em] text-muted">Hata kodu</p>
              <p className="mt-2 break-all font-mono text-sm leading-7 text-text">{error.digest}</p>
            </div>
          ) : null}
          <button
            type="button"
            onClick={() => reset()}
            className="rounded-2xl bg-primary px-5 py-3 text-sm font-black text-white"
          >
            Tekrar dene
          </button>
        </div>
      </section>
    </main>
  );
}
