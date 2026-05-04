import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const metadata: Metadata = { title: 'Puan Kartlarım | Yeedoy', robots: { index: false, follow: false } };

export default async function LoyaltyPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type CardRow = { id: string; business_id: string; points: number; tier: string | null; businesses: { name: string; slug: string } | null };
  let list: CardRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('loyalty_cards')
      .select('id, business_id, points, tier, businesses(name, slug)')
      .eq('user_id', user!.id)
      .order('points', { ascending: false }) as { data: CardRow[] | null; error: any };
    if (!error || error.code !== '42P01') list = data ?? [];
  } catch { list = []; }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profile" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Profile Dön</Link>
        <h1 className="mb-6 text-2xl font-[900] text-textStrong">Puan Kartlarım</h1>
        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="font-[700] text-textStrong mb-2">Henüz puan kartınız yok</p>
            <p className="text-sm text-muted">Ziyaret ettiğiniz işletmelerin puan kartları burada görünecek.</p>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2">
            {list.map(card => (
              <div key={card.id} className="rounded-2xl border border-border bg-card p-5">
                <p className="font-[700] text-textStrong">{card.businesses?.name ?? 'Bilinmeyen'}</p>
                <p className="mt-1 text-3xl font-[900] text-primary">{card.points}</p>
                <p className="text-xs text-muted">puan</p>
                {card.tier && <span className="mt-2 inline-block rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-[700] text-amber-700">{card.tier}</span>}
                {card.businesses?.slug && (
                  <Link href={`/m/${card.businesses.slug}`} className="mt-3 block text-[12px] font-[700] text-primary hover:underline cursor-pointer">Menüye Git →</Link>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
