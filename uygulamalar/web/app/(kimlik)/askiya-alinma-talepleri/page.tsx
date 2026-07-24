import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  title: 'Süspanse Taleplerim | Yeedoy',
  robots: { index: false, follow: false },
};

const STATUS_MAP: Record<string, { label: string; className: string }> = {
  pending:  { label: 'Beklemede', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-red-700' },
  resolved: { label: 'Çözüldü', className: 'bg-zinc-100 text-zinc-500' },
};

export default async function ClaimsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  type ClaimRow = { id: string; status: string; reason: string | null; created_at: string; resolved_at: string | null; businesses: { name: string; slug: string } | null };
  let list: ClaimRow[] = [];

  try {
    const { data, error } = await (supabase as any)
      .from('suspended_claims')
      .select('id, status, reason, created_at, resolved_at, businesses(name, slug)')
      .eq('user_id', user!.id)
      .order('created_at', { ascending: false }) as { data: ClaimRow[] | null; error: any };
    if (!error || error.code !== '42P01') list = data ?? [];
  } catch {
    list = [];
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Profile Dön</Link>
        <h1 className="mb-6 text-2xl font-black text-textStrong">Süspanse Taleplerim</h1>

        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="font-bold text-textStrong">Talep bulunamadı</p>
            <p className="mt-2 text-sm text-muted">Süspanse talepleriniz burada listelenecek.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map((c) => {
              const status = STATUS_MAP[c.status] ?? { label: c.status, className: 'bg-zinc-100 text-zinc-500' };
              return (
                <div key={c.id} className="rounded-2xl border border-border bg-card p-5">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-bold text-textStrong">{c.businesses?.name ?? 'Bilinmeyen İşletme'}</p>
                      {c.reason && <p className="mt-0.5 text-sm text-muted">{c.reason}</p>}
                      <p className="mt-1 text-[12px] text-muted">
                        Talep: {new Date(c.created_at).toLocaleDateString('tr-TR')}
                        {c.resolved_at && ` · Çözüm: ${new Date(c.resolved_at).toLocaleDateString('tr-TR')}`}
                      </p>
                    </div>
                    <span className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-bold ${status.className}`}>{status.label}</span>
                  </div>
                  {c.businesses?.slug && (
                    <Link href={`/m/${c.businesses.slug}`} className="mt-3 inline-flex text-[12px] font-bold text-primary hover:underline cursor-pointer">Menüyü Gör →</Link>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}

