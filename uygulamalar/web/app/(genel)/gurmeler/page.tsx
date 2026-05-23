import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';

export const revalidate = 300;

export const metadata: Metadata = {
  title: 'Gurmeler | Yeedoy',
  description: "Yeedoy'un en aktif gurme topluluğunu keşfedin.",
};

type GourmetRow = {
  id: string;
  username: string | null;
  display_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  city: string | null;
  review_count: number;
  helpful_received: number;
};

export default async function GourmetsPage() {
  const supabase = createSupabasePublicClient();

  let gourmets: GourmetRow[] = [];
  try {
    const { data } = await (supabase as any)
      .rpc('get_top_gourmets_v1', { p_limit: 48 })
      .then((r: any) => r) as { data: GourmetRow[] | null };
    if (data && data.length > 0) gourmets = data;
  } catch { /* fall through */ }

  // Fallback: query user_profiles with review count
  if (gourmets.length === 0) {
    try {
      const { data } = await (supabase as any)
        .from('user_profiles')
        .select('id, username, display_name, avatar_url, bio, city')
        .not('display_name', 'is', null)
        .order('created_at', { ascending: false })
        .limit(48) as { data: GourmetRow[] | null };
      gourmets = (data ?? []).map((p) => ({ ...p, review_count: 0, helpful_received: 0 }));
    } catch { gourmets = []; }
  }

  return (
    <PublicShell>
      <main>
        <section
          className="py-12 text-white"
          style={{ background: 'linear-gradient(135deg, #5c1515 0%, #7f1d1d 60%, #991b1b 100%)' }}
        >
          <Container>
            <p className="mb-2 text-xs font-[900] uppercase tracking-widest text-white/60">Topluluk</p>
            <h1 className="text-3xl font-[900] sm:text-4xl">Yeedoy Gurmeleri</h1>
            <p className="mt-3 max-w-xl text-sm leading-relaxed text-white/80">
              Lezzetleri keşfeden, fiyatları doğrulayan ve topluluğa katkı sağlayan gurmeler.
            </p>
          </Container>
        </section>

        <Container className="py-10">
          {gourmets.length === 0 ? (
            <div className="rounded-2xl border border-border bg-card p-10 text-center">
              <p className="font-[700] text-textStrong">Henüz gurme profili yok</p>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {gourmets.map((g) => {
                const name = g.display_name ?? g.username ?? 'Anonim Gurme';
                const href = g.username ? `/gurmeler/${g.username}` : '#';
                return (
                  <Link
                    key={g.id}
                    href={href}
                    className="flex items-start gap-4 rounded-2xl border border-border bg-card p-4 transition-all hover:-translate-y-0.5 hover:border-primary/25 hover:shadow-sm"
                  >
                    {/* Avatar */}
                    <div className="h-12 w-12 shrink-0 overflow-hidden rounded-full border border-border bg-primary/10 flex items-center justify-center text-lg font-[900] text-primary">
                      {g.avatar_url
                        ? <Image src={g.avatar_url} alt={name} width={48} height={48} className="h-full w-full object-cover" />
                        : name[0].toUpperCase()}
                    </div>

                    {/* Info */}
                    <div className="min-w-0 flex-1">
                      <p className="truncate font-[900] text-textStrong">{name}</p>
                      {g.bio && <p className="mt-0.5 line-clamp-1 text-xs text-muted">{g.bio}</p>}
                      <div className="mt-2 flex flex-wrap items-center gap-3 text-[11px] text-muted">
                        {g.city && <span>{g.city}</span>}
                        {g.review_count > 0 && <span>{g.review_count} yorum</span>}
                        {g.helpful_received > 0 && <span>{g.helpful_received} beğeni</span>}
                      </div>
                    </div>
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
