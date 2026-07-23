import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

type Props = { searchParams: Promise<Record<string, string | undefined>> };

// Turkce karsiligi: /(genel)/kesif (canonical).
export default async function DiscoverRedirectPage({ searchParams }: Props): Promise<never> {
  const params = await searchParams;
  const qs = new URLSearchParams(
    Object.entries(params).filter(([, v]) => v !== undefined) as [string, string][],
  ).toString();
  redirect(`/kesif${qs ? `?${qs}` : ''}`);
}
