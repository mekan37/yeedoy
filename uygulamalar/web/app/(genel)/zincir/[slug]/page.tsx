import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

interface ChainBranch {
  chain_id: string;
  chain_name: string;
  chain_description: string | null;
  business_id: string;
  business_name: string;
  branch_label: string | null;
  city: string;
  district: string;
  address: string | null;
  is_open_now: boolean | null;
  distance_km: number | null;
  avg_price_cents: number | null;
  chain_avg_price_cents: number | null;
  price_delta_pct: number | null;
}

type AnySupabase = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

export async function generateMetadata(
  { params }: { params: Promise<{ slug: string }> }
): Promise<Metadata> {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as unknown as AnySupabase).rpc('get_chain_overview_v2', {
    p_chain_id: slug,
    p_limit: 1,
  });
  const name = (data as ChainBranch[] | null)?.[0]?.chain_name ?? 'Zincir';
  return { title: `${name} | Yeedoy` };
}

export default async function ZincirPage(
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();

  const { data, error } = await (supabase as unknown as AnySupabase).rpc('get_chain_overview_v2', {
    p_chain_id: slug,
    p_limit: 50,
  });

  if (error || !data || (data as ChainBranch[]).length === 0) {
    notFound();
  }

  const branches = data as ChainBranch[];
  const chainName = branches[0].chain_name;
  const chainDescription = branches[0].chain_description;

  return (
    <div className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-8">
        {/* Header */}
        <div className="mb-6">
          <p className="text-xs font-bold uppercase tracking-wide text-muted mb-1">Zincir İşletme</p>
          <h1 className="text-2xl font-black text-textStrong">{chainName}</h1>
          {chainDescription && (
            <p className="mt-2 text-sm text-muted">{chainDescription}</p>
          )}
          <p className="mt-1 text-sm text-muted">{branches.length} şube</p>
        </div>

        {/* Şube listesi */}
        <div className="flex flex-col gap-3">
          {branches.map((branch) => (
            <div
              key={branch.business_id}
              className="rounded-xl border border-border bg-card p-4 flex flex-col gap-2"
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-base font-extrabold text-textStrong">
                      {branch.business_name}
                    </span>
                    {branch.branch_label && (
                      <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-bold text-primary">
                        {branch.branch_label}
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-muted mt-0.5">
                    {branch.district}, {branch.city}
                  </p>
                  {branch.address && (
                    <p className="text-xs text-muted mt-0.5">{branch.address}</p>
                  )}
                </div>
                <div className="flex flex-col items-end gap-1 shrink-0">
                  {branch.is_open_now !== null && (
                    <span
                      className={`rounded-full px-2 py-0.5 text-[11px] font-bold ${
                        branch.is_open_now
                          ? 'bg-green-50 text-green-700'
                          : 'bg-red-50 text-red-600'
                      }`}
                    >
                      {branch.is_open_now ? 'Açık' : 'Kapalı'}
                    </span>
                  )}
                  {branch.price_delta_pct !== null &&
                    Math.abs(Number(branch.price_delta_pct)) >= 1 && (
                      <span
                        className={`text-[11px] font-bold ${
                          Number(branch.price_delta_pct) > 0
                            ? 'text-red-500'
                            : 'text-green-600'
                        }`}
                      >
                        {Number(branch.price_delta_pct) > 0 ? '+' : ''}
                        {Math.round(Number(branch.price_delta_pct))}% fiyat
                      </span>
                    )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
