import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('group_requests').select('title').eq('id', id).single() as { data: { title: string } | null };
  return { title: data ? `${data.title} | Yeedoy` : 'Grup İsteği | Yeedoy', robots: { index: false, follow: false } };
}

export default async function GroupRequestDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();

  type Req = { id: string; title: string; description: string | null; status: string; participant_count: number; min_participants: number; target_date: string | null; created_at: string; businesses: { name: string; slug: string } | null };
  const { data: req } = await (supabase as any).from('group_requests').select('id, title, description, status, participant_count, min_participants, target_date, created_at, businesses(name, slug)').eq('id', id).single() as { data: Req | null };
  if (!req) notFound();

  const STATUS_MAP: Record<string, { label: string; className: string }> = {
    open:      { label: 'Açık',        className: 'bg-green-50 text-green-700' },
    fulfilled: { label: 'Tamamlandı',  className: 'bg-blue-50 text-blue-700' },
    expired:   { label: 'Süresi Doldu', className: 'bg-zinc-100 text-zinc-500' },
    cancelled: { label: 'İptal',       className: 'bg-red-50 text-red-700' },
  };
  const st = STATUS_MAP[req.status] ?? { label: req.status, className: 'bg-zinc-100 text-zinc-500' };
  const progress = Math.min(100, Math.round((req.participant_count / req.min_participants) * 100));

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/grup-istekleri" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Grup İsteklerim</Link>
        <div className="rounded-2xl border border-border bg-card p-6">
          <div className="flex items-start justify-between gap-3 mb-4">
            <h1 className="text-xl font-[900] text-textStrong">{req.title}</h1>
            <span className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-[700] ${st.className}`}>{st.label}</span>
          </div>
          {req.description && <p className="mb-4 text-sm text-muted">{req.description}</p>}
          {req.businesses && (
            <p className="mb-4 text-sm text-textStrong">
              İşletme: <Link href={`/m/${req.businesses.slug}`} className="text-primary hover:underline cursor-pointer">{req.businesses.name}</Link>
            </p>
          )}
          <div className="mb-4">
            <div className="flex items-center justify-between mb-1">
              <span className="text-sm font-[700] text-textStrong">{req.participant_count} / {req.min_participants} katılımcı</span>
              <span className="text-sm font-[700] text-primary">%{progress}</span>
            </div>
            <div className="h-2 w-full rounded-full bg-border overflow-hidden">
              <div className="h-full rounded-full bg-primary transition-all" style={{ width: `${progress}%` }} />
            </div>
          </div>
          {req.target_date && <p className="text-sm text-muted">Hedef Tarih: {new Date(req.target_date).toLocaleDateString('tr-TR')}</p>}
          <p className="mt-1 text-[12px] text-muted">Oluşturulma: {new Date(req.created_at).toLocaleDateString('tr-TR')}</p>
        </div>
      </div>
    </main>
  );
}

