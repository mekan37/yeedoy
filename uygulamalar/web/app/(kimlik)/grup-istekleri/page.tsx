import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = { title: 'Grup İsteklerim | Yeedoy', robots: { index: false, follow: false } };

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  open:      { label: 'Açık',       className: 'bg-green-50 text-green-700' },
  fulfilled: { label: 'Tamamlandı', className: 'bg-blue-50 text-blue-700' },
  expired:   { label: 'Süresi Doldu', className: 'bg-zinc-100 text-zinc-500' },
  cancelled: { label: 'İptal',      className: 'bg-red-50 text-red-700' },
};

export default async function GroupRequestsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type ReqRow = { id: string; title: string; status: string; participant_count: number; created_at: string; businesses: { name: string; slug: string } | null };
  let list: ReqRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('group_requests')
      .select('id, title, status, participant_count, created_at, businesses(name, slug)')
      .eq('creator_id', user!.id)
      .order('created_at', { ascending: false }) as { data: ReqRow[] | null; error: any };
    if (!error || error.code !== '42P01') list = data ?? [];
  } catch { list = []; }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-[900] text-textStrong">Grup İsteklerim</h1>
          <Link href="/grup-istekleri/new" className="rounded-xl bg-primary px-4 py-2 text-sm font-[700] text-white cursor-pointer">+ Yeni İstek</Link>
        </div>
        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="font-[700] text-textStrong mb-2">Henüz grup isteği oluşturmadınız</p>
            <Link href="/grup-istekleri/new" className="text-sm text-primary hover:underline cursor-pointer">İlk grup isteğinizi oluşturun →</Link>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map(r => {
              const st = STATUS_MAP[r.status] ?? { label: r.status, className: 'bg-zinc-100 text-zinc-500' };
              return (
                <Link key={r.id} href={`/grup-istekleri/${r.id}`} className="flex items-center justify-between rounded-2xl border border-border bg-card px-5 py-4 transition-colors hover:border-primary/30 cursor-pointer">
                  <div>
                    <p className="font-[700] text-textStrong">{r.title}</p>
                    <p className="mt-0.5 text-[12px] text-muted">{r.businesses?.name ?? ''} · {r.participant_count} katılımcı · {new Date(r.created_at).toLocaleDateString('tr-TR')}</p>
                  </div>
                  <span className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-[700] ${st.className}`}>{st.label}</span>
                </Link>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}

