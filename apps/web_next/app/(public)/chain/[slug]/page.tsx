import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const revalidate = 300;

type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('business_chains').select('name').eq('slug', slug).single() as { data: { name: string } | null };
  return { title: data ? `${data.name} | Yeedoy` : 'Zincir | Yeedoy' };
}

export default async function ChainPage({ params }: Props) {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();

  type Chain = { id: string; name: string; description: string | null; logo_url: string | null };
  type BizRow = { id: string; name: string; slug: string; city: string | null; is_active: boolean };

  let chain: Chain | null = null;
  let branches: BizRow[] = [];
  let chainNotFound = false;

  try {
    const { data, error } = await (supabase as any).from('business_chains').select('id, name, description, logo_url').eq('slug', slug).single() as { data: Chain | null; error: any };
    if (error?.code === '42P01' || !data) { chainNotFound = true; }
    else {
      chain = data;
      const { data: bizData } = await (supabase as any).from('businesses').select('id, name, slug, city, is_active').eq('chain_id', chain.id).eq('is_active', true).order('name') as { data: BizRow[] | null };
      branches = bizData ?? [];
    }
  } catch {
    chainNotFound = true;
  }

  if (chainNotFound) notFound();

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-10">
        <Link href="/discover" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Keşfete Dön</Link>

        <div className="mb-8 flex items-center gap-4">
          {chain?.logo_url && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={chain.logo_url} alt={chain!.name} className="h-16 w-16 rounded-2xl border border-border object-cover" />
          )}
          <div>
            <h1 className="text-3xl font-[900] text-textStrong">{chain?.name}</h1>
            {chain?.description && <p className="mt-1 text-sm text-muted">{chain.description}</p>}
          </div>
        </div>

        <h2 className="mb-4 text-lg font-[800] text-textStrong">{branches.length} Şube</h2>

        {branches.length === 0 ? (
          <p className="text-sm text-muted">Bu zincire ait şube bulunamadı.</p>
        ) : (
          <div className="flex flex-col gap-3">
            {branches.map((biz) => (
              <Link
                key={biz.id}
                href={`/m/${biz.slug}`}
                className="flex items-center justify-between rounded-2xl border border-border bg-card px-5 py-4 transition-colors hover:border-primary/30 cursor-pointer"
              >
                <div>
                  <p className="font-[700] text-textStrong">{biz.name}</p>
                  {biz.city && <p className="mt-0.5 text-[12px] text-muted">{biz.city}</p>}
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted"><path d="M9 18l6-6-6-6" /></svg>
              </Link>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
