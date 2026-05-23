import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const metadata: Metadata = { title: 'Fiyat Alarmlarım | Yeedoy', robots: { index: false, follow: false } };

export default async function PriceAlertsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type AlertRow = { id: string; target_price_cents: number; currency: string; is_active: boolean; menu_items: { name: string } | null };
  let list: AlertRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('price_alerts')
      .select('id, target_price_cents, currency, is_active, menu_items(name)')
      .eq('user_id', user!.id)
      .order('created_at', { ascending: false }) as { data: AlertRow[] | null; error: any };
    if (!error || error.code !== '42P01') list = data ?? [];
  } catch { list = []; }

  function fmt(cents: number, cur: string) {
    return (cents / 100).toLocaleString('tr-TR', { style: 'currency', currency: cur || 'TRY' });
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profile" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Profile Dön</Link>
        <h1 className="mb-6 text-2xl font-[900] text-textStrong">Fiyat Alarmlarım</h1>
        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="font-[700] text-textStrong mb-2">Henüz fiyat alarmınız yok</p>
            <p className="text-sm text-muted">Bir ürün belirli bir fiyata düştüğünde bildirim almak için alarm ekleyin.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map(a => (
              <div key={a.id} className="flex items-center justify-between rounded-2xl border border-border bg-card px-5 py-4">
                <div>
                  <p className="font-[700] text-textStrong">{a.menu_items?.name ?? 'Bilinmeyen ürün'}</p>
                  <p className="mt-0.5 text-sm text-muted">Hedef: {fmt(a.target_price_cents, a.currency)}</p>
                </div>
                <span className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-[700] ${a.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'}`}>
                  {a.is_active ? 'Aktif' : 'Pasif'}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
