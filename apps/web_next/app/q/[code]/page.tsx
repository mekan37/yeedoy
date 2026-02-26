import { redirect, notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export default async function ShortLinkPage({ params }: { params: Promise<{ code: string }> }) {
  const { code } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: businessBySlug } = await supabase
    .from('businesses')
    .select('slug,is_active')
    .eq('slug', code)
    .maybeSingle();

  if (businessBySlug?.slug && businessBySlug.is_active) {
    redirect(`/b/${businessBySlug.slug}?lang=tr`);
  }

  notFound();
}
