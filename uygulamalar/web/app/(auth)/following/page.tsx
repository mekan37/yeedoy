import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const metadata: Metadata = { title: 'Takip Ettiklerim | Yeedoy', robots: { index: false, follow: false } };

export default async function FollowingPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type FollowRow = { followed_id: string; user_profiles: { display_name: string | null; avatar_url: string | null } | null };
  let list: FollowRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('user_follows')
      .select('followed_id, user_profiles!followed_id(display_name, avatar_url)')
      .eq('follower_id', user!.id)
      .order('created_at', { ascending: false }) as { data: FollowRow[] | null; error: any };
    if (!error || error.code !== '42P01') list = data ?? [];
  } catch { list = []; }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profile" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Profile Dön</Link>
        <h1 className="mb-6 text-2xl font-[900] text-textStrong">Takip Ettiklerim</h1>
        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="font-[700] text-textStrong mb-2">Henüz kimseyi takip etmiyorsunuz</p>
            <Link href="/feed" className="text-sm text-primary hover:underline cursor-pointer">Gurmeleri keşfedin →</Link>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map(f => {
              const name = f.user_profiles?.display_name ?? 'Anonim Gurme';
              return (
                <div key={f.followed_id} className="flex items-center gap-4 rounded-2xl border border-border bg-card px-5 py-4">
                  <div className="h-10 w-10 shrink-0 overflow-hidden rounded-full border border-border bg-primary/10 flex items-center justify-center text-base font-[900] text-primary">
                    {f.user_profiles?.avatar_url
                      ? <Image unoptimized src={f.user_profiles.avatar_url} alt={name} width={40} height={40} className="h-full w-full object-cover" />
                      : name[0].toUpperCase()}
                  </div>
                  <p className="font-[700] text-textStrong">{name}</p>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
