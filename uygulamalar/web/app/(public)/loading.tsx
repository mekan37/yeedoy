export default function PublicMenuLoading() {
  return (
    <main className="mx-auto min-h-screen w-full max-w-7xl px-4 py-5 sm:px-6 sm:py-6">
      <section className="overflow-hidden rounded-[32px] border border-border bg-card shadow-yd2">
        <div className="h-[300px] animate-pulse bg-[radial-gradient(circle_at_top_left,_rgba(255,255,255,0.3),_transparent_42%),linear-gradient(135deg,_rgb(var(--yd-color-primary-rgb)),_rgb(var(--yd-color-primary-strong-rgb)))]" />
      </section>

      <section className="sticky top-3 z-20 mt-6 rounded-[28px] border border-border bg-card/90 p-3 shadow-yd2 backdrop-blur">
        <div className="mb-3 h-10 w-40 animate-pulse rounded-2xl bg-bg" />
        <div className="flex gap-2 overflow-hidden">
          <div className="h-11 w-28 animate-pulse rounded-full bg-bg" />
          <div className="h-11 w-32 animate-pulse rounded-full bg-bg" />
          <div className="h-11 w-24 animate-pulse rounded-full bg-bg" />
          <div className="h-11 w-36 animate-pulse rounded-full bg-bg" />
        </div>
      </section>

      <section className="mt-6 grid gap-3 md:grid-cols-[1.25fr_0.75fr]">
        <div className="h-28 animate-pulse rounded-[28px] border border-border bg-card shadow-yd1" />
        <div className="h-28 animate-pulse rounded-[28px] border border-border bg-card shadow-yd1" />
      </section>

      <section className="mt-6 grid gap-6 lg:grid-cols-[0.75fr_1.25fr]">
        <div className="space-y-4">
          <div className="h-52 animate-pulse rounded-[28px] border border-border bg-card shadow-yd1" />
          <div className="h-44 animate-pulse rounded-[28px] border border-border bg-card shadow-yd1" />
        </div>

        <div className="space-y-3">
          <div className="h-44 animate-pulse rounded-[28px] border border-border bg-card shadow-yd1" />
          <div className="h-44 animate-pulse rounded-[28px] border border-border bg-card shadow-yd1" />
          <div className="h-44 animate-pulse rounded-[28px] border border-border bg-card shadow-yd1" />
        </div>
      </section>
    </main>
  );
}
