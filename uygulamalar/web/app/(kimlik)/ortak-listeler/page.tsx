import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { ListeOlusturButonu } from './liste-olustur';

export const metadata: Metadata = {
  title: 'İşbirlikçi Listeler | Yeedoy',
  robots: { index: false, follow: false },
};

type ListRow = {
  id: string;
  title: string;
  description: string | null;
  owner_id: string;
  created_at: string;
  item_count: number;
  member_count: number;
};

export default async function CollabListsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  let lists: ListRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('collab_lists')
      .select(`
        id, title, description, owner_id, created_at,
        item_count:collab_list_items(count),
        member_count:collab_list_members(count),
        collab_list_members!inner(user_id)
      `)
      .eq('collab_list_members.user_id', user!.id)
      .order('created_at', { ascending: false }) as { data: any[] | null; error: any };

    if (!error || error.code !== '42P01') {
      lists = (data ?? []).map((row) => ({
        ...row,
        item_count: row.item_count?.[0]?.count ?? 0,
        member_count: row.member_count?.[0]?.count ?? 0,
      }));
    }
  } catch { lists = []; }

  const owned = lists.filter((l) => l.owner_id === user!.id);
  const joined = lists.filter((l) => l.owner_id !== user!.id);

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">← Profilime Dön</Link>

        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-[900] text-textStrong">İşbirlikçi Listeler</h1>
            {lists.length > 0 && (
              <p className="mt-0.5 text-sm text-muted">{lists.length} liste</p>
            )}
          </div>
          <ListeOlusturButonu />
        </div>

        {lists.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="text-3xl mb-3">📋</p>
            <p className="font-[700] text-textStrong mb-2">Henüz liste yok</p>
            <p className="text-sm text-muted mb-6">Arkadaşlarınızla ortak yemek listeleri oluşturun, oylayın ve paylaşın.</p>
            <ListeOlusturButonu />
          </div>
        ) : (
          <div className="flex flex-col gap-6">
            {owned.length > 0 && (
              <section>
                <p className="mb-3 text-xs font-[900] uppercase tracking-wide text-muted">Oluşturduklarım</p>
                <div className="flex flex-col gap-3">
                  {owned.map((l) => <ListCard key={l.id} list={l} userId={user!.id} />)}
                </div>
              </section>
            )}
            {joined.length > 0 && (
              <section>
                <p className="mb-3 text-xs font-[900] uppercase tracking-wide text-muted">Katıldıklarım</p>
                <div className="flex flex-col gap-3">
                  {joined.map((l) => <ListCard key={l.id} list={l} userId={user!.id} />)}
                </div>
              </section>
            )}
          </div>
        )}
      </div>
    </main>
  );
}

function ListCard({ list, userId }: { list: ListRow; userId: string }) {
  const isOwner = list.owner_id === userId;
  return (
    <Link
      href={`/ortak-listeler/${list.id}`}
      className="flex items-center gap-4 rounded-2xl border border-border bg-card px-5 py-4 transition-all hover:-translate-y-0.5 hover:border-primary/25 hover:shadow-sm"
    >
      <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[var(--yd-color-primary-soft)] text-primary">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <line x1="8" y1="6" x2="21" y2="6" /><line x1="8" y1="12" x2="21" y2="12" /><line x1="8" y1="18" x2="21" y2="18" />
          <line x1="3" y1="6" x2="3.01" y2="6" /><line x1="3" y1="12" x2="3.01" y2="12" /><line x1="3" y1="18" x2="3.01" y2="18" />
        </svg>
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <p className="truncate font-[900] text-textStrong">{list.title}</p>
          {isOwner && <span className="shrink-0 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-[900] text-primary">Sahibi</span>}
        </div>
        {list.description && <p className="mt-0.5 truncate text-xs text-muted">{list.description}</p>}
        <p className="mt-1 text-[11px] text-muted">
          {list.item_count} öğe · {list.member_count} üye
        </p>
      </div>
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted" aria-hidden="true">
        <polyline points="9 18 15 12 9 6" />
      </svg>
    </Link>
  );
}
