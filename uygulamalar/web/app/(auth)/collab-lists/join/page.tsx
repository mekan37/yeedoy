import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const metadata: Metadata = {
  title: 'Listeye Katıl | Yeedoy',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ token?: string }> };

export default async function CollabListJoinPage({ searchParams }: Props) {
  const { token } = await searchParams;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!token) {
    return (
      <main className="min-h-screen bg-bg">
        <div className="mx-auto max-w-md px-4 py-20 text-center">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full border border-border bg-bg text-muted"><svg viewBox="0 0 24 24" className="h-6 w-6 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg></div>
          <h1 className="text-xl font-[900] text-textStrong mb-2">Geçersiz Bağlantı</h1>
          <p className="text-muted mb-6">Bu davet bağlantısı geçerli değil veya süresi dolmuş.</p>
          <Link href="/collab-lists" className="text-sm text-primary hover:underline cursor-pointer">Listelerime dön →</Link>
        </div>
      </main>
    );
  }

  let listId: string | null = null;
  let listTitle: string | null = null;
  let joinError: string | null = null;

  try {
    const { data: listData, error: lookupError } = await (supabase as any)
      .from('collab_lists')
      .select('id, title')
      .eq('invite_token', token)
      .single() as { data: { id: string; title: string } | null; error: any };

    if (lookupError || !listData) {
      joinError = 'Geçersiz veya süresi dolmuş davet bağlantısı.';
    } else {
      listId = listData.id;
      listTitle = listData.title;

      const rpcResult = await supabase.rpc('join_collab_list_v1' as never, { p_invite_token: token } as never) as { error: any };
      if (rpcResult.error) {
        joinError = 'Listeye katılırken bir hata oluştu.';
      }
    }
  } catch {
    joinError = 'Listeye katılırken bir hata oluştu.';
  }

  if (!joinError && listId) {
    redirect(`/collab-lists/${listId}`);
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-md px-4 py-20 text-center">
        {joinError ? (
          <>
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full border border-amber-200 bg-amber-50 text-amber-600"><svg viewBox="0 0 24 24" className="h-6 w-6 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg></div>
            <h1 className="text-xl font-[900] text-textStrong mb-2">Katılım Başarısız</h1>
            <p className="text-muted mb-6">{joinError}</p>
            <Link href="/collab-lists" className="text-sm text-primary hover:underline cursor-pointer">Listelerime dön →</Link>
          </>
        ) : (
          <>
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full border border-green-200 bg-green-50 text-green-600"><svg viewBox="0 0 24 24" className="h-6 w-6 fill-none stroke-current" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg></div>
            <h1 className="text-xl font-[900] text-textStrong mb-2">
              {listTitle ? `"${listTitle}" listesine katıldınız` : 'Listeye katıldınız'}
            </h1>
            <p className="text-muted mb-6">Yönlendiriliyorsunuz...</p>
          </>
        )}
      </div>
    </main>
  );
}
