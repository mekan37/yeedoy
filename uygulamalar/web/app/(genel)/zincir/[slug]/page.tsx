import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { AppSectionHeader } from '@/src/ui/bilesenler/uygulama-bolum-basligi';
import { BusinessTile } from '@/src/ui/bilesenler/isletme-karti';

export const revalidate = 300;

type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('business_chains').select('name, description').eq('slug', slug).single() as { data: { name: string; description: string | null } | null };
  return {
    title: data ? `${data.name} | Yeedoy` : 'Zincir | Yeedoy',
    description: data?.description ?? undefined,
  };
}

export default async function ChainPage({ params }: Props) {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();

  type Chain = { id: string; name: string; description: string | null; logo_url: string | null };
  type BizRow = { id: string; name: string; slug: string; city: string | null; category: string | null; is_verified: boolean };

  let chain: Chain | null = null;
  let branches: BizRow[] = [];

  try {
    const { data, error } = await (supabase as any)
      .from('business_chains').select('id, name, description, logo_url').eq('slug', slug).single() as { data: Chain | null; error: any };
    if (error?.code === '42P01' || !data) notFound();
    chain = data;
    const { data: bizData } = await (supabase as any)
      .from('businesses').select('id, name, slug, city, category, is_verified').eq('chain_id', chain!.id).eq('is_active', true).order('name') as { data: BizRow[] | null };
    branches = bizData ?? [];
  } catch {
    notFound();
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 pb-16 py-10">

        {/* Back */}
        <Link href="/kesif"
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted transition-colors hover:text-primary">
          <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current" aria-hidden="true"><path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/></svg>
          Keşfete Dön
        </Link>

        {/* Chain header */}
        <div className="mb-8 flex items-center gap-5">
          {chain?.logo_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={chain.logo_url} alt={chain.name} className="h-20 w-20 shrink-0 rounded-[18px] border border-border object-cover shadow-yd1" loading="eager" />
          ) : (
            <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-[18px] text-3xl font-[900] text-white shadow-yd1"
              style={{ background: 'var(--yd-gradient-primary)' }}>
              {chain?.name[0]}
            </div>
          )}
          <div className="min-w-0">
            <h1 className="font-display text-3xl font-[900] text-textStrong">{chain?.name}</h1>
            {chain?.description && <p className="mt-1 text-sm leading-relaxed text-muted">{chain.description}</p>}
          </div>
        </div>

        {/* Branches */}
        <AppSectionHeader title={`${branches.length} Şube`} className="mb-4" />

        {branches.length === 0 ? (
          <div className="rounded-[20px] border border-border bg-card p-10 text-center text-muted">
            Bu zincire ait şube bulunamadı.
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {branches.map((biz) => (
              <BusinessTile key={biz.id} slug={biz.slug} name={biz.name}
                subtitle={biz.city ?? undefined} category={biz.category ?? undefined}
                isVerified={biz.is_verified} />
            ))}
          </div>
        )}
      </div>
    </main>
  );
}

