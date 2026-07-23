import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

type Props = { searchParams: Promise<{ city?: string; category?: string }> };

// Turkce karsiligi: /(genel)/en-iyiler (canonical).
export default async function TopRedirectPage({ searchParams }: Props): Promise<never> {
  const { city, category } = await searchParams;
  const query = new URLSearchParams();
  if (city) query.set('city', city);
  if (category) query.set('category', category);
  const qs = query.toString();
  redirect(`/en-iyiler${qs ? `?${qs}` : ''}`);
}
