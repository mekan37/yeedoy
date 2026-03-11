import { notFound, redirect } from 'next/navigation';

export const revalidate = 120;

type LegacySlugPageProps = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ lang?: string }>;
};

export default async function LegacyBusinessPage({ params, searchParams }: LegacySlugPageProps) {
  const [{ slug }, { lang }] = await Promise.all([params, searchParams]);

  if (/^[0-9a-fA-F-]{36}$/.test(slug)) {
    redirect(`/m/${slug}${lang ? `?lang=${lang}` : ''}`);
  }

  notFound();
}
