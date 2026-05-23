import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';

export const revalidate = 120;

export const metadata: Metadata = {
  title: 'Askıda Öğünler | Yeedoy',
  description: 'İhtiyaç sahipleri için topluluk destekli askıda öğün bağışları.',
};

type SuspendedMeal = {
  id: string;
  business_id: string;
  business_name: string;
  business_slug: string | null;
  city: string | null;
  available_count: number;
  category: string | null;
  description: string | null;
  created_at: string;
};

export default async function SuspendedMealsPage() {
  const supabase = createSupabasePublicClient();

  let meals: SuspendedMeal[] = [];
  try {
    const { data } = await (supabase as any)
      .rpc('get_suspended_meals_public_v1', { p_limit: 40 })
      .then((r: any) => r) as { data: SuspendedMeal[] | null };
    if (data && data.length > 0) meals = data;
  } catch { /* fall through */ }

  // Fallback: query directly
  if (meals.length === 0) {
    try {
      const { data } = await (supabase as any)
        .from('suspended_meals')
        .select('id, business_id, available_count, description, created_at, businesses(name, slug, city, category)')
        .gt('available_count', 0)
        .order('created_at', { ascending: false })
        .limit(40) as { data: any[] | null };

      meals = (data ?? []).map((row: any) => ({
        id: row.id,
        business_id: row.business_id,
        business_name: row.businesses?.name ?? 'İşletme',
        business_slug: row.businesses?.slug ?? null,
        city: row.businesses?.city ?? null,
        category: row.businesses?.category ?? null,
        available_count: row.available_count ?? 0,
        description: row.description ?? null,
        created_at: row.created_at,
      }));
    } catch { meals = []; }
  }

  return (
    <PublicShell>
      <main>
        {/* Hero */}
        <section className="border-b border-border bg-cardAlt py-10">
          <Container>
            <div className="max-w-2xl">
              <p className="mb-2 text-xs font-[900] uppercase tracking-widest text-primary">Topluluk Dayanışması</p>
              <h1 className="text-3xl font-[900] text-textStrong sm:text-4xl">Askıda Öğünler</h1>
              <p className="mt-3 text-sm leading-relaxed text-muted">
                İşletmelerin askıya bıraktığı öğünler ihtiyaç sahibi misafirler tarafından ücretsiz alınabilir.
                Bir öğün bağışlamak için favori restoranınızı ziyaret edin.
              </p>
              <div className="mt-6 flex flex-wrap gap-3">
                <Link
                  href="/kesif"
                  className="inline-flex min-h-[44px] items-center rounded-2xl px-5 text-sm font-[800] text-white"
                  style={{ background: 'var(--yd-gradient-primary)' }}
                >
                  İşletme Keşfet
                </Link>
                <div className="inline-flex min-h-[44px] items-center gap-2 rounded-2xl border border-border bg-card px-5 text-sm font-[700] text-textStrong">
                  <span className="h-2 w-2 rounded-full bg-success" />
                  {meals.length} aktif öğün
                </div>
              </div>
            </div>
          </Container>
        </section>

        {/* How it works */}
        <Container className="py-8">
          <div className="mb-8 grid gap-4 sm:grid-cols-3">
            {[
              { step: '1', title: 'Restoran Öder', desc: 'İşletme öğün bedelini ödeyerek sisteme askıya alır' },
              { step: '2', title: 'Kart Göster', desc: 'İhtiyaç sahibi müşteri masaya gelip "Askıda öğün var mı?" der' },
              { step: '3', title: 'Herkese Açık', desc: 'Menüden bir öğün ücretsiz seçilir, sistem güncellenir' },
            ].map(({ step, title, desc }) => (
              <div key={step} className="rounded-2xl border border-border bg-card p-5">
                <div className="mb-3 flex h-9 w-9 items-center justify-center rounded-xl bg-primary text-sm font-[900] text-white">{step}</div>
                <p className="font-[900] text-textStrong">{title}</p>
                <p className="mt-1 text-sm text-muted leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>

          {/* Meal list */}
          <h2 className="mb-5 text-xl font-[900] text-textStrong">Şu An Aktif İşletmeler</h2>

          {meals.length === 0 ? (
            <div className="rounded-2xl border border-border bg-card p-10 text-center">
              <p className="text-3xl mb-3">🍽️</p>
              <p className="font-[700] text-textStrong mb-2">Şu an aktif askıda öğün yok</p>
              <p className="text-sm text-muted">Yeni öğünler eklendiğinde burada görünecek.</p>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2">
              {meals.map((meal) => {
                const href = meal.business_slug ? `/isletme/${meal.business_slug}` : '#';
                return (
                  <Link
                    key={meal.id}
                    href={href}
                    className="flex items-start gap-4 rounded-2xl border border-border bg-card p-5 transition-all hover:-translate-y-0.5 hover:border-primary/25 hover:shadow-sm"
                  >
                    {/* Count badge */}
                    <div className="flex h-12 w-12 shrink-0 flex-col items-center justify-center rounded-xl bg-success/10 text-center">
                      <span className="text-lg font-[900] text-success leading-none">{meal.available_count}</span>
                      <span className="text-[10px] font-[700] text-success/80">öğün</span>
                    </div>

                    <div className="min-w-0 flex-1">
                      <p className="font-[900] text-textStrong">{meal.business_name}</p>
                      <p className="mt-0.5 text-xs text-muted">{[meal.category, meal.city].filter(Boolean).join(' · ')}</p>
                      {meal.description && (
                        <p className="mt-1.5 line-clamp-2 text-xs leading-relaxed text-muted">{meal.description}</p>
                      )}
                    </div>

                    <svg viewBox="0 0 24 24" className="h-4 w-4 shrink-0 fill-none stroke-current text-muted mt-1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <polyline points="9 18 15 12 9 6" />
                    </svg>
                  </Link>
                );
              })}
            </div>
          )}
        </Container>
      </main>
    </PublicShell>
  );
}
