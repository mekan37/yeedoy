import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { AvantajKullanButonu } from './avantaj-kullan';
import { KoduGoster } from './kodu-goster';

export const metadata: Metadata = { title: 'Avantajlarım | Yeedoy', robots: { index: false, follow: false } };

type PerkRow = {
  id: string; title: string; description: string | null;
  expires_at: string | null; is_used: boolean;
  businesses: { name: string; slug: string } | null;
};

export default async function PerksPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  let list: PerkRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('user_perks')
      .select('id, title, description, expires_at, is_used, businesses(name, slug)')
      .eq('user_id', user!.id)
      .order('is_used')
      .order('expires_at', { ascending: true }) as { data: PerkRow[] | null; error: any };
    if (!error || error.code !== '42P01') list = data ?? [];
  } catch { list = []; }

  const active = list.filter((p) => !p.is_used);
  const used = list.filter((p) => p.is_used);

  function isExpired(expires_at: string | null) {
    if (!expires_at) return false;
    return new Date(expires_at) < new Date();
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">← Profilime Dön</Link>
        <div className="mb-6 flex items-center gap-3">
          <h1 className="text-2xl font-black text-textStrong">Avantajlarım</h1>
          {active.length > 0 && (
            <span className="rounded-full bg-primary px-2 py-0.5 text-[11px] font-bold text-white">{active.length}</span>
          )}
        </div>

        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="text-3xl mb-3">🎁</p>
            <p className="font-bold text-textStrong mb-2">Henüz avantajınız yok</p>
            <p className="text-sm text-muted">Kazandığınız ödüller ve indirim kuponları burada görünecek.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-6">
            {/* Active perks */}
            {active.length > 0 && (
              <section>
                <p className="mb-3 text-xs font-black uppercase tracking-wide text-muted">Kullanılabilir</p>
                <div className="flex flex-col gap-3">
                  {active.map((perk) => {
                    const expired = isExpired(perk.expires_at);
                    return (
                      <div key={perk.id} className={`rounded-2xl border bg-card p-5 ${expired ? 'border-border opacity-60' : 'border-primary/20'}`}>
                        <div className="flex items-start justify-between gap-3">
                          <div className="min-w-0 flex-1">
                            <p className="font-black text-textStrong">{perk.title}</p>
                            {perk.description && <p className="mt-0.5 text-sm text-muted">{perk.description}</p>}
                            {perk.businesses && (
                              <Link href={`/isletme/${perk.businesses.slug}`} className="mt-1 block text-[12px] font-bold text-primary hover:underline">
                                {perk.businesses.name}
                              </Link>
                            )}
                            {perk.expires_at && (
                              <p className={`mt-1 text-[11px] ${expired ? 'text-danger' : 'text-muted'}`}>
                                {expired ? 'Süresi doldu · ' : 'Son: '}{new Date(perk.expires_at).toLocaleDateString('tr-TR')}
                              </p>
                            )}
                          </div>
                          <div className="flex flex-col items-end gap-2">
                            <AvantajKullanButonu perkId={perk.id} disabled={expired} />
                            {!expired && <KoduGoster kod={perk.id.slice(0, 8).toUpperCase()} />}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </section>
            )}

            {/* Used perks */}
            {used.length > 0 && (
              <section>
                <p className="mb-3 text-xs font-black uppercase tracking-wide text-muted">Kullanılanlar</p>
                <div className="flex flex-col gap-3">
                  {used.map((perk) => (
                    <div key={perk.id} className="flex items-center justify-between gap-3 rounded-2xl border border-border bg-card px-5 py-4 opacity-60">
                      <div>
                        <p className="text-sm font-bold text-textStrong">{perk.title}</p>
                        {perk.businesses && <p className="text-[12px] text-muted">{perk.businesses.name}</p>}
                      </div>
                      <span className="rounded-full bg-border px-2.5 py-1 text-[10px] font-bold text-muted">Kullanıldı</span>
                    </div>
                  ))}
                </div>
              </section>
            )}
          </div>
        )}
      </div>
    </main>
  );
}
