import { buildCanonicalPublicMenuHref, generatePublicMenuMetadata, hasLegacyBusinessPath, renderPublicMenuRoute } from '../../page';
import { normalizeDisplayParams } from '@/src/lib/yol-normalizasyonu';
import { redirect } from 'next/navigation';
import MenuNotFound from '../../not-found';
import { getPublicMenuPageData } from '@/src/lib/acik-menu-sayfasi';
import { isUuid } from '@/src/lib/yol-normalizasyonu';

type ItemPageProps = {
  params: Promise<{ slug: string; itemId: string }>;
  searchParams: Promise<{ lang?: string; theme?: string; src?: string; preview?: string }>;
};

// bkz. src/lib/revalidate.ts — REVALIDATE.MEDIUM (120)
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
  // notFound() burada KULLANILMIYOR: (genel) route grubunun loading.tsx'i bu
  // sayfayı da bir Suspense sınırına sarıyor, içinde fırlatılan notFound()
  // Next.js 16.2.11'de client'a hiç swap edilmiyor (bkz. ../../page.tsx).
  if (!isUuid(itemId)) return <MenuNotFound />;
  const data = await getPublicMenuPageData({ businessSlugOrId: slug, selectedItemId: itemId });
  if (!data) return <MenuNotFound />;
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
