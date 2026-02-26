import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PublicMenuClient } from '@/src/ui/sections/public-menu-client';

export const revalidate = 120;

export async function generateMetadata(
  { params }: { params: Promise<{ slug: string }> },
): Promise<Metadata> {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: business } = await supabase
    .from('businesses')
    .select('name,slug')
    .eq('slug', slug)
    .eq('is_active', true)
    .maybeSingle();
  if (!business) return { title: 'Menu bulunamadi' };
  return {
    title: `${business.name} | QR Menu`,
    openGraph: {
      title: `${business.name} | QR Menu`,
      images: [`/api/og?title=${encodeURIComponent(business.name)}`],
    },
  };
}

type PageProps = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ lang?: string }>;
};

export default async function PublicMenuPage({ params, searchParams }: PageProps) {
  const [{ slug }, { lang }] = await Promise.all([params, searchParams]);
  const supabase = await createSupabaseServerClient();
  const { data: business } = await supabase
    .from('businesses')
    .select('*')
    .eq('slug', slug)
    .eq('is_active', true)
    .single();

  if (!business) notFound();

  const [{ data: categories }, { data: items }, { data: translations }] = await Promise.all([
    supabase.from('menu_categories').select('*').eq('business_id', business.id).eq('is_active', true).order('sort_order'),
    supabase
      .from('menu_items')
      .select('id,business_id,category_id,name,description,price_cents,currency,tags,image_url,is_available,sort_order,created_at,updated_at')
      .eq('business_id', business.id)
      .order('sort_order'),
    supabase.from('menu_translations').select('*').in('entity_type', ['business', 'category', 'item']),
  ]);

  const locale = lang || 'tr';
  const businessName =
    translations?.find((t) => t.entity_type === 'business' && t.entity_id === business.id && t.locale === locale)?.name ??
    business.name;

  return (
    <main className="mx-auto min-h-screen w-full max-w-3xl p-4">
      <header className="mb-4 rounded-2xl bg-white p-4 shadow-sm">
        <h1 className="text-3xl font-extrabold">{businessName}</h1>
        <p className="text-slate-500">{business.city ?? ''} {business.district ?? ''}</p>
      </header>

      <PublicMenuClient
        locale={locale}
        showPrices
        theme="minimal"
        categories={(categories ?? []) as any}
        items={(items ?? []) as any}
        translations={(translations ?? []) as any}
      />
    </main>
  );
}
