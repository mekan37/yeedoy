import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';

export const revalidate = 300;

export const metadata: Metadata = {
  title: 'Zincirler | Yeedoy',
  description: "Türkiye'nin önde gelen restoran ve kafe zincirlerini keşfet.",
};

type ChainRow = {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  logo_url: string | null;
  branch_count: number;
};

export default async function ZincirlerPage() {
  const supabase = createSupabasePublicClient();

  let chains: ChainRow[] = [];
  try {
    const { data } = await (supabase as any)
      .from('business_chains')
      .select('id, name, slug, description, logo_url, branch_count:businesses(count)')
      .order('name', { ascending: true })
      .limit(60) as { data: any[] | null };

    chains = (data ?? []).map((row: any) => ({
      id: row.id,
      name: row.name,
      slug: row.slug,
      description: row.description ?? null,
      logo_url: row.logo_url ?? null,
      branch_count: row.branch_count?.[0]?.count ?? 0,
    }));
  } catch { chains = []; }

  return (
    <PublicShell>
      <main>
        <section className="border-b border-border bg-cardAlt py-10">
          <Container>
            <p className="mb-2 text-xs font-[900] uppercase tracking-widest text-primary">Zincirler</p>
            <h1 className="text-3xl font-[900] text-textStrong sm:text-4xl">Restoran Zincirleri</h1>
            <p className="mt-3 text-sm leading-relaxed text-muted">
              Birden fazla şubede hizmet veren zincirleri keşfet, tüm şubelerini karşılaştır.
            </p>
          </Container>
        </section>

        <Container className="py-10">
          {chains.length === 0 ? (
            <div className="rounded-2xl border border-border bg-card p-10 text-center">
              <p className="font-[700] text-textStrong">Zincir bulunamadı</p>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {chains.map((chain) => (
                <Link
                  key={chain.id}
                  href={`/zincir/${chain.slug}`}
                  className="flex items-start gap-4 rounded-2xl border border-border bg-card p-5 transition-all hover:-translate-y-0.5 hover:border-primary/25 hover:shadow-sm"
                >
                  {/* Logo */}
                  <div className="flex h-12 w-12 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-border bg-cardAlt text-xl font-[900] text-primary">
                    {chain.logo_url
                      ? <Image src={chain.logo_url} alt={chain.name} width={48} height={48} className="h-full w-full object-cover" />
                      : chain.name[0]}
                  </div>

                  {/* Info */}
                  <div className="min-w-0 flex-1">
                    <p className="font-[900] text-textStrong">{chain.name}</p>
                    {chain.description && (
                      <p className="mt-0.5 line-clamp-2 text-xs leading-relaxed text-muted">{chain.description}</p>
                    )}
                    {chain.branch_count > 0 && (
                      <p className="mt-2 text-[11px] font-[900] text-primary">{chain.branch_count} şube</p>
                    )}
                  </div>

                  <svg viewBox="0 0 24 24" className="h-4 w-4 shrink-0 fill-none stroke-current text-muted mt-1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <polyline points="9 18 15 12 9 6" />
                  </svg>
                </Link>
              ))}
            </div>
          )}
        </Container>
      </main>
    </PublicShell>
  );
}
