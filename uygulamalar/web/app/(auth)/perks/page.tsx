import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const metadata: Metadata = { title: 'Avantajlarım | Yeedoy', robots: { index: false, follow: false } };

export default async function PerksPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type PerkRow = { id: string; title: string; description: string | null; expires_at: string | null; is_used: boolean; businesses: { name: string; slug: string } | null };
  let list: PerkRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('user_perks')
      .select('id, title, description, expires_at, is_used, businesses(name, slug)')
      .eq('user_id', user!.id)
      .order('expires_at', { ascending: true }) as { data: PerkRow[] | null; error: any };
    if (!error || error.code !== '42P01') list = data ?? [];
  } catch { list = []; }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profile" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Profile Dön</Link>
        <h1 className="mb-6 text-2xl font-[900] text-textStrong">Avantajlarım</h1>
        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="font-[700] text-textStrong mb-2">Henüz avantajınız yok</p>
            <p className="text-sm text-muted">Kazandığınız ödüller ve kuponlar burada görünecek.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map(perk => (
              <div key={perk.id} className={`rounded-2xl border bg-card p-5 ${perk.is_used ? 'border-border opacity-60' : 'border-border'}`}>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-[700] text-textStrong">{perk.title}</p>
                    {perk.description && <p className="mt-0.5 text-sm text-muted">{perk.description}</p>}
                    {perk.businesses && <p className="mt-1 text-[12px] text-muted">{perk.businesses.name}</p>}
                    {perk.expires_at && <p className="mt-1 text-[11px] text-muted">Son: {new Date(perk.expires_at).toLocaleDateString('tr-TR')}</p>}
                  </div>
                  {perk.is_used && <span className="shrink-0 rounded-full bg-zinc-100 px-2 py-1 text-[10px] font-[700] text-zinc-500">Kullanıldı</span>}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
