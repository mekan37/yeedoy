import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const metadata: Metadata = { title: 'Önerilerim | Yeedoy', robots: { index: false, follow: false } };

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  pending:  { label: 'Beklemede', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-red-700' },
};

export default async function SuggestionsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type SugRow = { id: string; name: string; city: string | null; category: string | null; status: string; created_at: string };
  let list: SugRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('business_suggestions')
      .select('id, name, city, category, status, created_at')
      .eq('submitted_by_email', user!.email ?? '')
      .order('created_at', { ascending: false }) as { data: SugRow[] | null; error: any };
    if (!error || error.code !== '42P01') list = data ?? [];
  } catch { list = []; }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profile" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Profile Dön</Link>
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-[900] text-textStrong">Önerilerim</h1>
          <Link href="/suggest" className="rounded-xl bg-primary px-4 py-2 text-sm font-[700] text-white cursor-pointer">+ Yeni Öneri</Link>
        </div>
        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="font-[700] text-textStrong mb-2">Henüz öneri göndermediniz</p>
            <Link href="/suggest" className="text-sm text-primary hover:underline cursor-pointer">İlk önerinizi gönderin →</Link>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map(s => {
              const st = STATUS_MAP[s.status] ?? { label: s.status, className: 'bg-zinc-100 text-zinc-500' };
              return (
                <div key={s.id} className="flex items-center justify-between rounded-2xl border border-border bg-card px-5 py-4">
                  <div>
                    <p className="font-[700] text-textStrong">{s.name}</p>
                    <p className="mt-0.5 text-[12px] text-muted">{[s.category, s.city].filter(Boolean).join(' · ')}</p>
                    <p className="mt-0.5 text-[11px] text-muted">{new Date(s.created_at).toLocaleDateString('tr-TR')}</p>
                  </div>
                  <span className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-[700] ${st.className}`}>{st.label}</span>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
