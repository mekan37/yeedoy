import { permanentRedirect } from 'next/navigation';

type Props = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ sort?: string; page?: string }>;
};

// /b/<slug>/reviews — bkz. üst dizindeki page.tsx'in yorumu. Asıl
// implementasyon /isletme/[slug]/yorumlar'da; sort/page parametreleri
// korunarak yönlendirilir.
export default async function BusinessShortLinkReviewsPage({ params, searchParams }: Props) {
  const { slug } = await params;
  const sp = await searchParams;
  const qs = new URLSearchParams();
  if (sp.sort) qs.set('sort', sp.sort);
  if (sp.page) qs.set('page', sp.page);
  const query = qs.toString();
  permanentRedirect(`/isletme/${slug}/yorumlar${query ? `?${query}` : ''}`);
}
