import { buildCanonicalPublicMenuHref, generatePublicMenuMetadata, hasLegacyBusinessPath, renderPublicMenuRoute } from '../../page';
import { normalizeDisplayParams } from '@/src/lib/yol-normalizasyonu';
import { notFound, redirect } from 'next/navigation';
import { getPublicMenuPageData } from '@/src/lib/acik-menu-sayfasi';
import { isUuid } from '@/src/lib/yol-normalizasyonu';

type CategoryPageProps = {
  params: Promise<{ slug: string; categoryId: string }>;
  searchParams: Promise<{ lang?: string; theme?: string; src?: string; preview?: string }>;
};

export const revalidate = 120;

export async function generateMetadata({ params, searchParams }: CategoryPageProps) {
  const [{ slug, categoryId }, rawSearchParams] = await Promise.all([params, searchParams]);
  return generatePublicMenuMetadata({
    businessSlugOrId: slug,
    categoryId,
    lang: rawSearchParams.lang,
    theme: rawSearchParams.theme,
  });
}

export default async function PublicCategoryPage({ params, searchParams }: CategoryPageProps) {
  const [{ slug, categoryId }, rawSearchParams] = await Promise.all([params, searchParams]);
  if (!isUuid(categoryId)) notFound();
  const data = await getPublicMenuPageData({ businessSlugOrId: slug });
  if (!data) notFound();
  const normalized = normalizeDisplayParams(rawSearchParams, {
    lang: data.presentation.defaultLang,
    theme: data.presentation.templateKey,
  });

  if (normalized.hasInvalidParams || hasLegacyBusinessPath(slug, data)) {
    redirect(
      buildCanonicalPublicMenuHref({
        data,
        categoryId,
        lang: normalized.lang,
        theme: normalized.theme,
        src: normalized.src,
        preview: normalized.preview,
      }),
    );
  }

  return renderPublicMenuRoute({
    businessSlugOrId: slug,
    selectedCategoryId: categoryId,
    lang: normalized.lang,
    theme: normalized.theme,
    src: normalized.src,
    preview: normalized.preview,
    data,
  });
}
