import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = { title: 'Puan Kartlarım | Yeedoy', robots: { index: false, follow: false } };

const TIER_CONFIG: Record<string, { label: string; emoji: string; next: number; color: string }> = {
  bronze:   { label: 'Bronz',   emoji: '🥉', next: 500,  color: '#cd7f32' },
  silver:   { label: 'Gümüş',   emoji: '🥈', next: 1500, color: '#9ca3af' },
  gold:     { label: 'Altın',   emoji: '🥇', next: 5000, color: '#f59e0b' },
  platinum: { label: 'Platin',  emoji: '💎', next: 99999, color: '#6366f1' },
};

function tierFor(points: number): { label: string; emoji: string; next: number; color: string } {
  if (points >= 5000) return TIER_CONFIG.platinum;
  if (points >= 1500) return TIER_CONFIG.gold;
  if (points >= 500)  return TIER_CONFIG.silver;
  return TIER_CONFIG.bronze;
}

function prevTierThreshold(points: number): number {
  if (points >= 5000) return 1500;
  if (points >= 1500) return 500;
  if (points >= 500)  return 0;
  return 0;
}

export default async function LoyaltyPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type CardRow = {
    id: string; business_id: string; points: number; tier: string | null;
    businesses: { name: string; slug: string; logo_url: string | null } | null;
  };
  let list: CardRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('loyalty_cards')
      .select('id, business_id, points, tier, businesses(name, slug, logo_url)')
      .eq('user_id', user!.id)
      .order('points', { ascending: false }) as { data: CardRow[] | null; error: any };
    if (!error || error.code !== '42P01') list = data ?? [];
  } catch { list = []; }

  const totalPoints = list.reduce((s, c) => s + c.points, 0);

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">← Profilime Dön</Link>

        <div className="mb-6 flex items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-[900] text-textStrong">Puan Kartlarım</h1>
            {list.length > 0 && (
              <p className="mt-1 text-sm text-muted">Toplam <span className="font-[900] text-primary">{totalPoints.toLocaleString('tr-TR')}</span> puan · {list.length} kart</p>
            )}
          </div>
          <Link href="/kesif" className="shrink-0 rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-[700] text-textStrong hover:border-primary/30">
            Yeni İşletme Keşfet
          </Link>
        </div>

        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="text-3xl mb-3">🎴</p>
            <p className="font-[700] text-textStrong mb-2">Henüz puan kartınız yok</p>
            <p className="text-sm text-muted mb-6">Ziyaret ettiğiniz işletmelerin puan kartları burada görünür.</p>
            <Link href="/kesif"
              className="inline-flex min-h-[44px] items-center rounded-2xl px-5 text-sm font-[800] text-white"
              style={{ background: 'var(--yd-gradient-primary)' }}>
              İşletmeleri Keşfet
            </Link>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2">
            {list.map((card) => {
              const tier = tierFor(card.points);
              const prev = prevTierThreshold(card.points);
              const progress = tier.next === 99999
                ? 100
                : Math.round(((card.points - prev) / (tier.next - prev)) * 100);
              const remaining = tier.next === 99999 ? 0 : tier.next - card.points;

              return (
                <div key={card.id}
                  className="flex flex-col rounded-2xl border border-border bg-card overflow-hidden shadow-yd1">
                  {/* Card gradient header */}
                  <div
                    className="px-5 py-4 text-white"
                    style={{ background: `linear-gradient(135deg, #5c1515 0%, #7f1d1d 100%)` }}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0">
                        <p className="truncate text-xs font-[700] text-white/70">
                          {card.businesses?.name ?? 'İşletme'}
                        </p>
                        <p className="text-3xl font-[900] text-white leading-tight">
                          {card.points.toLocaleString('tr-TR')}
                        </p>
                        <p className="text-xs text-white/70">puan</p>
                      </div>
                      <span className="text-2xl" aria-hidden="true">{tier.emoji}</span>
                    </div>
                  </div>

                  {/* Progress + info */}
                  <div className="flex-1 px-5 py-4">
                    <div className="mb-1 flex items-center justify-between">
                      <span className="text-xs font-[900] text-textStrong">{tier.label}</span>
                      {tier.next !== 99999 && (
                        <span className="text-[11px] text-muted">{remaining.toLocaleString('tr-TR')} puan kaldı</span>
                      )}
                    </div>
                    <div className="h-2 overflow-hidden rounded-full bg-border">
                      <div
                        className="h-full rounded-full transition-all duration-500"
                        style={{ width: `${Math.min(100, progress)}%`, background: 'var(--yd-gradient-primary)' }}
                      />
                    </div>
                    {tier.next !== 99999 && (
                      <p className="mt-1 text-[11px] text-muted">
                        Sonraki seviye: {TIER_CONFIG[Object.entries(TIER_CONFIG).find(([, v]) => v.next === tier.next)?.[0] === 'bronze' ? 'silver' : Object.entries(TIER_CONFIG).find(([, v]) => v.next === tier.next)?.[0] === 'silver' ? 'gold' : 'platinum']?.label ?? ''}
                      </p>
                    )}
                  </div>

                  {/* Actions */}
                  <div className="flex items-center justify-between border-t border-border px-5 py-3">
                    {card.businesses?.slug ? (
                      <Link href={`/isletme/${card.businesses.slug}`} className="text-xs font-[700] text-muted hover:text-primary">
                        İşletme sayfası
                      </Link>
                    ) : <span />}
                    {card.businesses?.slug ? (
                      <Link
                        href={`/m/${card.businesses.slug}`}
                        className="rounded-xl bg-primary px-3 py-1.5 text-[11px] font-[900] text-white hover:brightness-105"
                      >
                        Menüyü Gör
                      </Link>
                    ) : null}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
