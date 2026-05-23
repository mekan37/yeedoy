import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const metadata: Metadata = {
  title: 'İşbirlikçi Listeler | Yeedoy',
  robots: { index: false, follow: false },
};

export default async function CollabListsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type ListRow = {
    id: string;
    title: string;
    description: string | null;
    owner_id: string;
    created_at: string;
  };

  let lists: ListRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('collab_lists')
      .select('id, title, description, owner_id, created_at, collab_list_members!inner(user_id)')
      .eq('collab_list_members.user_id', user!.id)
      .order('created_at', { ascending: false }) as { data: ListRow[] | null; error: any };
    if (!error || error.code !== '42P01') lists = data ?? [];
  } catch { lists = []; }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profile" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">
          ← Profile Dön
        </Link>
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-[900] text-textStrong">İşbirlikçi Listeler</h1>
        </div>

        {lists.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full border border-border bg-bg text-muted"><ListIcon /></div>
            <p className="font-[700] text-textStrong mb-2">Henüz liste yok</p>
            <p className="text-sm text-muted">Bir listeye katılmak için davet bağlantısı kullanın.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {lists.map((l) => (
              <Link
                key={l.id}
                href={`/collab-lists/${l.id}`}
                className="flex items-center gap-4 rounded-2xl border border-border bg-card px-5 py-4 hover:border-primary/30 hover:bg-card/80 transition-colors cursor-pointer"
              >
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary">
                  <ListIcon />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-[800] text-textStrong truncate">{l.title}</p>
                  {l.description && (
                    <p className="text-xs text-muted mt-0.5 truncate">{l.description}</p>
                  )}
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted shrink-0">
                  <polyline points="9 18 15 12 9 6" />
                </svg>
              </Link>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}

function ListIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="8" y1="6" x2="21" y2="6" />
      <line x1="8" y1="12" x2="21" y2="12" />
      <line x1="8" y1="18" x2="21" y2="18" />
      <line x1="3" y1="6" x2="3.01" y2="6" />
      <line x1="3" y1="12" x2="3.01" y2="12" />
      <line x1="3" y1="18" x2="3.01" y2="18" />
    </svg>
  );
}
