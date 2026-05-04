import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { voteOnItem } from './actions';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any)
    .from('collab_lists')
    .select('title')
    .eq('id', id)
    .single() as { data: { title: string } | null };
  return {
    title: data ? `${data.title} | İşbirlikçi Liste` : 'Liste Detayı',
    robots: { index: false, follow: false },
  };
}

export default async function CollabListDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type ListDetail = {
    id: string;
    title: string;
    description: string | null;
    owner_id: string;
    invite_token: string | null;
  };

  type ListItem = {
    id: string;
    content: string;
    added_by: string;
    up_votes: number;
    down_votes: number;
    created_at: string;
  };

  type Member = {
    user_id: string;
    role: string;
    user_profiles: { display_name: string | null } | null;
  };

  let list: ListDetail | null = null;
  let items: ListItem[] = [];
  let members: Member[] = [];

  try {
    const detailRpc = await supabase.rpc('get_collab_list_detail_v1' as never, { p_list_id: id } as never) as { data: any; error: any };
    if (detailRpc.data) {
      const d = detailRpc.data as any;
      list    = d.list    ?? null;
      items   = d.items   ?? [];
      members = d.members ?? [];
    }
  } catch {
    const { data: rawList, error } = await (supabase as any)
      .from('collab_lists')
      .select('id, title, description, owner_id, invite_token')
      .eq('id', id)
      .single() as { data: ListDetail | null; error: any };
    if (!error) {
      list = rawList;
      const { data: rawItems } = await (supabase as any)
        .from('collab_list_items')
        .select('id, content, added_by, up_votes, down_votes, created_at')
        .eq('list_id', id)
        .order('up_votes', { ascending: false }) as { data: ListItem[] | null };
      items = rawItems ?? [];
    }
  }

  if (!list) notFound();

  const userVote = (item: ListItem) => {
    if (item.added_by === user!.id) return null;
    return null;
  };

  const shareUrl = list.invite_token
    ? `${process.env.NEXT_PUBLIC_SITE_URL ?? ''}/collab-lists/join?token=${list.invite_token}`
    : null;

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/collab-lists" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">
          ← Listelerim
        </Link>

        <div className="mb-6">
          <h1 className="text-2xl font-[900] text-textStrong mb-1">{list.title}</h1>
          {list.description && <p className="text-muted text-sm">{list.description}</p>}
          <div className="flex items-center gap-3 mt-2">
            <span className="text-xs text-muted">{items.length} öğe · {members.length} üye</span>
            {shareUrl && (
              <span className="text-xs text-muted">Davet bağlantısı mevcut</span>
            )}
          </div>
        </div>

        {items.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-8 text-center">
            <p className="text-muted">Bu listede henüz öğe yok.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {items.map((item) => {
              const score = (item.up_votes ?? 0) - (item.down_votes ?? 0);
              return (
                <div key={item.id} className="flex items-center gap-4 rounded-2xl border border-border bg-card px-5 py-4">
                  <div className="flex flex-col items-center gap-1">
                    <form action={async () => { 'use server'; await voteOnItem(id, item.id, 1); }}>
                      <button type="submit" className="flex items-center justify-center h-7 w-7 rounded-lg border border-border text-muted hover:text-primary hover:border-primary/30 transition-colors cursor-pointer" title="Beğen">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="18 15 12 9 6 15" /></svg>
                      </button>
                    </form>
                    <span className="text-sm font-[800] text-textStrong">{score}</span>
                    <form action={async () => { 'use server'; await voteOnItem(id, item.id, -1); }}>
                      <button type="submit" className="flex items-center justify-center h-7 w-7 rounded-lg border border-border text-muted hover:text-primary hover:border-primary/30 transition-colors cursor-pointer" title="Beğenme">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="6 9 12 15 18 9" /></svg>
                      </button>
                    </form>
                  </div>
                  <p className="flex-1 text-sm font-[700] text-textStrong">{item.content}</p>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
