import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

type LoginRedirectPageProps = {
  searchParams: Promise<{ redirect?: string; tab?: string }>;
};

// Turkce karsiligi: /giris (canonical, middleware LOGIN_PATH artik /giris kullaniyor).
export default async function LoginRedirectPage({ searchParams }: LoginRedirectPageProps): Promise<never> {
  const params = await searchParams;
  const query = new URLSearchParams();
  if (params.redirect) query.set('redirect', params.redirect);
  if (params.tab) query.set('tab', params.tab);
  const qs = query.toString();
  redirect(`/giris${qs ? `?${qs}` : ''}`);
}
