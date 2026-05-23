import { buildCanonicalPublicMenuHref, generatePublicMenuMetadata, hasLegacyBusinessPath, renderPublicMenuRoute } from '../../page';
import { normalizeDisplayParams } from '@/src/lib/yol-normalizasyonu';
import { notFound, redirect } from 'next/navigation';
import { getPublicMenuPageData } from '@/src/lib/acik-menu-sayfasi';
import { isUuid } from '@/src/lib/yol-normalizasyonu';

type ItemPageProps = {
  params: Promise<{ slug: string; itemId: string }>;
  searchParams: Promise<{ lang?: string; theme?: string; src?: string; preview?: string }>;
};

export const revalidate = 120;

export async function generateMetadata({ params, searchParams }: ItemPageProps) {
  const [{ slug, itemId }, rawSearchParams] = await Promise.all([params, searchParams]);
  return generatePublicMenuMetadata({
    businessSlugOrId: slug,
    itemId,
    lang: rawSearchParams.lang,
    theme: rawSearchParams.theme,
  });
}

export default async function PublicItemPage({ params, searchParams }: ItemPageProps) {
  const [{ slug, itemId }, rawSearchParams] = await Promise.all([params, searchParams]);
  if (!isUuid(itemId)) notFound();
  const data = await getPublicMenuPageData({ businessSlugOrId: slug, selectedItemId: itemId });
  if (!data) notFound();
  const normalized = normalizeDisplayParams(rawSearchParams, {
    lang: data.presentation.defaultLang,
    theme: data.presentation.templateKey,
  });

  if (normalized.hasInvalidParams || hasLegacyBusinessPath(slug, data)) {
    redirect(
      buildCanonicalPublicMenuHref({
        data,
        itemId,
        lang: normalized.lang,
        theme: normalized.theme,
        src: normalized.src,
        preview: normalized.preview,
      }),
    );
  }

  return renderPublicMenuRoute({
    businessSlugOrId: slug,
    selectedItemId: itemId,
    lang: normalized.lang,
    theme: normalized.theme,
    src: normalized.src,
    preview: normalized.preview,
    data,
  });
}
