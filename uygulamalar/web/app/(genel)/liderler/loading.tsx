export default function HeroesLoading() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <div className="mb-8">
          <div className="h-3 w-32 mb-2 animate-pulse rounded-lg bg-border" />
          <div className="h-9 w-52 mb-2 animate-pulse rounded-xl bg-border" />
          <div className="h-4 w-48 animate-pulse rounded-lg bg-border" />
        </div>
        <div className="flex flex-col gap-3">
          {Array.from({ length: 10 }).map((_, i) => (
            <div key={i} className="flex items-center gap-4 rounded-2xl border border-border bg-card px-5 py-4">
              <div className="h-8 w-8 animate-pulse rounded-full bg-border" />
              <div className="h-10 w-10 shrink-0 animate-pulse rounded-full bg-border" />
              <div className="flex-1 space-y-2">
                <div className="h-4 w-32 animate-pulse rounded-lg bg-border" />
                <div className="h-3 w-20 animate-pulse rounded-lg bg-border" />
              </div>
              <div className="h-7 w-12 animate-pulse rounded-lg bg-border" />
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
