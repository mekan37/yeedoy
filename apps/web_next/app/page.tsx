export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-6xl items-center px-4 py-10 sm:px-6">
      <section className="w-full overflow-hidden rounded-[36px] border border-border bg-card shadow-yd3">
        <div className="bg-[radial-gradient(circle_at_top_left,_rgba(255,255,255,0.24),_transparent_38%),linear-gradient(135deg,_rgb(var(--yd-color-primary-rgb)),_rgb(var(--yd-color-primary-strong-rgb)))] px-8 py-10 text-white sm:px-12 sm:py-14">
          <p className="text-xs font-black uppercase tracking-[0.32em] text-white/75">Yeedoy QR Menu</p>
          <h1 className="mt-4 max-w-3xl text-4xl font-black leading-tight sm:text-6xl">
            Public menu and QR generation, without moving admin CRUD into Next.js.
          </h1>
          <p className="mt-5 max-w-2xl text-sm leading-8 text-white/85 sm:text-base">
            This app renders only the public restaurant menu experience, SEO layer, theme system, analytics hooks,
            and QR assets. Owner and admin write flows remain in the separate panel application.
          </p>
        </div>

        <div className="grid gap-6 px-8 py-8 sm:grid-cols-[1.2fr_0.8fr] sm:px-12 sm:py-10">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">Active routes</p>
            <div className="mt-4 grid gap-3">
              <RouteCard route="/m/:publicSlugOrId" description="Public menu home" />
              <RouteCard route="/m/:publicSlugOrId/c/:categoryId" description="Category-focused menu view" />
              <RouteCard route="/m/:publicSlugOrId/i/:itemId" description="Item detail sheet route" />
              <RouteCard route="/qr/:businessId" description="QR generation and link copy" />
              <RouteCard route="/q/:shortCode" description="Deterministic short redirect" />
            </div>
          </div>

          <div className="rounded-[28px] border border-border bg-bg p-5">
            <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">Notes</p>
            <ul className="mt-4 space-y-3 text-sm leading-7 text-text">
              <li>Published menu reads only. No admin or owner CRUD screens live here.</li>
              <li>Canonical public menu routes prefer `public_slug`, then `slug`, then `businessId`.</li>
              <li>Tracking is privacy-friendly and rate-limited.</li>
            </ul>
            <p className="mt-6 rounded-2xl border border-border bg-card px-4 py-3 text-sm font-semibold text-textStrong">
              QR route template: <span className="font-black">/qr/:businessId</span>
            </p>
          </div>
        </div>
      </section>
    </main>
  );
}

function RouteCard({ route, description }: { route: string; description: string }) {
  return (
    <div className="rounded-[24px] border border-border bg-cardAlt px-4 py-4">
      <p className="text-sm font-black text-textStrong">{route}</p>
      <p className="mt-1 text-sm text-muted">{description}</p>
    </div>
  );
}
