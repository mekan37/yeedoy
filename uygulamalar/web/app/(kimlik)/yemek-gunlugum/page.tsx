import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  title: 'Yemek Günlüğüm | Yeedoy',
  robots: { index: false, follow: false },
};

function fmtTL(cents: number, currency = 'TRY') {
  return new Intl.NumberFormat('tr-TR', { style: 'currency', currency, maximumFractionDigits: 0 }).format(cents / 100);
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' });
}

function StarRow({ rating }: { rating: number }) {
  return (
    <span className="text-xs">
      {[1,2,3,4,5].map((n) => (
        <span key={n} className={n <= rating ? 'text-amber-400' : 'text-zinc-200'}>★</span>
      ))}
    </span>
  );
}

export default async function YemekGunluguPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/yemek-gunlugum');

  const { data: entries } = await (supabase as any).rpc('get_my_food_journal_v1', { p_limit: 100 });
  const { data: summary } = await (supabase as any).rpc('get_my_spending_summary_v1', { p_months: 3 });

  const list = (entries ?? []) as any[];
  const months = (summary ?? []) as any[];

  const totalCents = months.reduce((s: number, m: any) => s + (m.total_cents ?? 0), 0);
  const totalVisits = list.length;
  const uniquePlaces = new Set(list.map((e: any) => e.business_id)).size;

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-10">
        <h1 className="mb-1 text-2xl font-[900] text-textStrong">Yemek Günlüğüm</h1>
        <p className="mb-8 text-sm text-muted">Gittiğin yerler ve harcamalarının özeti</p>

        {/* Özet kartlar */}
        <div className="mb-8 grid grid-cols-3 gap-3">
          {[
            { label: 'Toplam Ziyaret', value: String(totalVisits) },
            { label: 'Farklı Yer', value: String(uniquePlaces) },
            { label: 'Son 3 Ay Harcama', value: totalCents > 0 ? fmtTL(totalCents) : '—' },
          ].map((s) => (
            <div key={s.label} className="rounded-2xl border border-border bg-card p-4 text-center">
              <p className="text-xl font-[900] text-textStrong">{s.value}</p>
              <p className="mt-0.5 text-xs text-muted">{s.label}</p>
            </div>
          ))}
        </div>

        {/* Aylık özet */}
        {months.length > 0 && (
          <div className="mb-8 rounded-2xl border border-border bg-card p-5">
            <h2 className="mb-4 text-base font-[900] text-textStrong">Aylık Özet</h2>
            <div className="space-y-3">
              {months.map((m: any) => {
                const label = new Date(m.month_label + '-01').toLocaleDateString('tr-TR', { month: 'long', year: 'numeric' });
                const maxCents = Math.max(...months.map((x: any) => x.total_cents || 0));
                const pct = maxCents > 0 ? Math.round((m.total_cents / maxCents) * 100) : 0;
                return (
                  <div key={m.month_label}>
                    <div className="mb-1 flex justify-between text-sm">
                      <span className="font-[700] text-textStrong">{label}</span>
                      <span className="font-[900] text-primary">
                        {m.total_cents > 0 ? fmtTL(m.total_cents) : '—'}
                      </span>
                    </div>
                    <div className="h-2 w-full rounded-full bg-border">
                      <div className="h-2 rounded-full bg-primary transition-all" style={{ width: `${pct}%` }} />
                    </div>
                    <p className="mt-1 text-xs text-muted">{m.visit_count} ziyaret · {m.unique_places} farklı yer</p>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Ziyaret listesi */}
        <h2 className="mb-4 text-base font-[900] text-textStrong">Ziyaretlerim</h2>
        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="text-muted">Henüz check-in yapmadınız.</p>
            <p className="mt-1 text-xs text-muted">İşletme sayfasında &ldquo;Buradayım&rdquo; butonunu kullanarak başlayın.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map((e: any) => (
              <div key={e.visit_id} className="rounded-2xl border border-border bg-card p-4">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1">
                    <a href={`/isletme/${e.business_slug}`} className="font-[900] text-textStrong hover:text-primary">
                      {e.business_name}
                    </a>
                    {(e.category || e.city) && (
                      <p className="text-xs text-muted">{[e.category, e.city].filter(Boolean).join(' · ')}</p>
                    )}
                    {e.personal_rating && (
                      <div className="mt-1"><StarRow rating={e.personal_rating} /></div>
                    )}
                    {e.personal_note && (
                      <p className="mt-1.5 text-sm leading-relaxed text-text">{e.personal_note}</p>
                    )}
                  </div>
                  <div className="shrink-0 text-right">
                    <p className="text-xs text-muted">{fmtDate(e.checked_in_at)}</p>
                    {e.amount_cents > 0 && (
                      <p className="mt-1 font-[900] text-primary">{fmtTL(e.amount_cents, e.currency)}</p>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
