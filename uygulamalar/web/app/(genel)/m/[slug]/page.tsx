import type { Metadata } from 'next';
import { notFound, redirect } from 'next/navigation';
import { AcikMenuIstemcisi } from '@/src/ui/bolumler/acik-menu-istemcisi';
import { getBrandThemeDefinition, getBrandThemeOptions, type BrandTheme } from '@/src/lib/marka-temasi';
import { getPublicMenuPageData, getTranslationValue } from '@/src/lib/acik-menu-sayfasi';
import { getBusinessHoursInfo } from '@/src/lib/veri/menu-okuma';
import { appConfig } from '@/src/lib/ayarlar';
import { formatBusinessLocation } from '@/src/lib/bicimlendirme';
import { getImageBlurDataUrl } from '@/src/lib/gorsel-yer-tutucu';
import { copy } from '@/src/lib/ceviri';
import { appendMediaVersion, buildMenuImageUrl } from '@/src/lib/medya-adresi';
import {
  buildBusinessMenuHref,
  resolveBusinessMenuPathKeyFromRecord,
} from '@/src/lib/menu-baglantilari';
import { isUuid, normalizeDisplayParams } from '@/src/lib/yol-normalizasyonu';

export const revalidate = 120;

type MenuPageProps = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ lang?: string; theme?: string; src?: string; preview?: string }>;
};

export async function generatePublicMenuMetadata(input: {
  businessSlugOrId: string;
  lang?: string | null;
  theme?: string | null;
  categoryId?: string | null;
  itemId?: string | null;
}): Promise<Metadata> {
  if (input.categoryId && !isUuid(input.categoryId)) {
    notFound();
  }

  if (input.itemId && !isUuid(input.itemId)) {
    notFound();
  }

  const data = await getPublicMenuPageData({
    businessSlugOrId: input.businessSlugOrId,
    selectedItemId: input.itemId ?? null,
  });

  if (!data) {
    notFound();
  }

  const normalized = normalizeDisplayParams(
    {
      lang: input.lang,
      theme: input.theme,
    },
    {
      lang: data.presentation.defaultLang,
      theme: data.presentation.templateKey,
    },
  );

  const businessName =
    getTranslationValue({
      translations: data.translations,
      entityType: 'business',
      entityId: data.business.id,
      locale: normalized.lang,
      field: 'name',
      fallback: data.business.name,
    }) ?? data.business.name;

  const categoryName = input.categoryId
    ? getTranslationValue({
      translations: data.translations,
      entityType: 'category',
      entityId: input.categoryId,
      locale: normalized.lang,
      field: 'name',
      fallback: null,
    })
    : null;

  const itemName = input.itemId
    ? getTranslationValue({
      translations: data.translations,
      entityType: 'item',
      entityId: input.itemId,
      locale: normalized.lang,
      field: 'name',
      fallback: null,
    })
    : null;

  const location = formatBusinessLocation(data.business);
  const title = [itemName, categoryName, businessName, 'Karekod Menu'].filter(Boolean).join(' | ');
  const description = [data.business.description, location, data.menu.title]
    .filter(Boolean)
    .join(' • ');

  return {
    metadataBase: new URL(appConfig.siteUrl()),
    title,
    description,
    alternates: {
      canonical: buildCanonicalPublicMenuHref({
        data,
        categoryId: input.categoryId,
        itemId: input.itemId,
        lang: normalized.lang,
        theme: normalized.theme,
      }),
    },
    openGraph: {
      title,
      description,
      images: data.media.coverUrl ? [data.media.coverUrl] : [`/sunucu/acik-grafik?title=${encodeURIComponent(businessName)}`],
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
    },
  };
}

export async function renderPublicMenuRoute(input: {
  businessSlugOrId: string;
  lang?: string | null;
  theme?: string | null;
  src?: string | null;
  preview?: boolean;
  selectedCategoryId?: string | null;
  selectedItemId?: string | null;
  data?: Awaited<ReturnType<typeof getPublicMenuPageData>> | null;
}) {
  if (input.selectedCategoryId && !isUuid(input.selectedCategoryId)) notFound();
  if (input.selectedItemId && !isUuid(input.selectedItemId)) notFound();

  const data =
    input.data ??
    (await getPublicMenuPageData({
      businessSlugOrId: input.businessSlugOrId,
      selectedItemId: input.selectedItemId ?? null,
    }));

  if (!data) notFound();

  const hoursInfo = await getBusinessHoursInfo(data.business.id);
  const isOpenNow = hoursInfo.isOpenNow;

  const normalized = normalizeDisplayParams(
    {
      lang: input.lang,
      theme: input.theme,
      src: input.src,
    },
    {
      lang: data.presentation.defaultLang,
      theme: data.presentation.templateKey,
    },
  );

  if (input.selectedCategoryId) {
    const hasCategory = data.categories.some((category) => category.id === input.selectedCategoryId);
    if (!hasCategory) notFound();
  }

  if (input.selectedItemId && !data.selectedItem) {
    notFound();
  }

  const businessName =
    getTranslationValue({
      translations: data.translations,
      entityType: 'business',
      entityId: data.business.id,
      locale: normalized.lang,
      field: 'name',
      fallback: data.business.name,
    }) ?? data.business.name;
  const themeDefinition = getBrandThemeDefinition(normalized.theme);
  const themeOptions = getBrandThemeOptions().map((option) => ({
    id: option.id,
    label: option.label[normalized.lang],
  }));
  const blurDataUrl = getImageBlurDataUrl(themeDefinition);

  const _schemaDow = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'] as const;
  const openingHoursSpecification = hoursInfo.weekly
    .filter((h) => !h.is_closed)
    .map((h) => ({
      '@type': 'OpeningHoursSpecification',
      dayOfWeek: `https://schema.org/${_schemaDow[h.day_of_week]}`,
      opens: h.open_time,
      closes: h.close_time,
    }));

  const schema = {
    '@context': 'https://schema.org',
    '@type': 'Restaurant',
    name: businessName,
    servesCuisine: data.business.category,
    image: data.media.coverUrl ?? data.media.logoUrl ?? undefined,
    description: data.business.description ?? undefined,
    ...(openingHoursSpecification.length > 0 ? { openingHoursSpecification } : {}),
    address: data.business.address
      ? {
          '@type': 'PostalAddress',
          addressLocality: data.business.district ?? undefined,
          addressRegion: data.business.city ?? undefined,
          streetAddress: data.business.address,
        }
      : undefined,
    hasMenu: {
      '@type': 'Menu',
      name: data.menu.title,
      hasMenuSection: data.categories.map((category) => ({
        '@type': 'MenuSection',
        name:
          getTranslationValue({
            translations: data.translations,
            entityType: 'category',
            entityId: category.id,
            locale: normalized.lang,
            field: 'name',
            fallback: `${data.business.category} ${category.sort_order + 1}`,
          }) ?? `${data.business.category} ${category.sort_order + 1}`,
        hasMenuItem: data.items
          .filter((item) => item.category_id === category.id)
          .map((item) => ({
            '@type': 'MenuItem',
            name:
              getTranslationValue({
                translations: data.translations,
                entityType: 'item',
                entityId: item.id,
                locale: normalized.lang,
                field: 'name',
                fallback: item.name,
              }) ?? item.name,
            description:
              getTranslationValue({
                translations: data.translations,
                entityType: 'item',
                entityId: item.id,
                locale: normalized.lang,
                field: 'description',
                fallback: item.description,
              }) ?? item.description,
            offers: {
              '@type': 'Offer',
              priceCurrency: item.currency,
              price: (item.price_cents / 100).toFixed(2),
              availability: item.is_available ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock',
            },
          })),
      })),
    },
  };

  const heroPreloadUrl = buildMenuImageUrl(
    appendMediaVersion(data.presentation.backgroundUrl || data.media.coverUrl, data.presentation.updatedAt),
    { width: 1400, quality: 85 },
  );

  return (
    <main className="mx-auto w-full max-w-7xl px-4 py-5 sm:px-6 sm:py-6">
      {heroPreloadUrl ? (
        // eslint-disable-next-line @next/next/no-head-element
        <link rel="preload" as="image" href={heroPreloadUrl} fetchPriority="high" />
      ) : null}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
      />
      <AcikMenuIstemcisi
        lang={normalized.lang}
        labels={copy[normalized.lang]}
        brandTheme={normalized.theme}
        themeDefinition={themeDefinition}
        themeOptions={themeOptions}
        blurDataUrl={blurDataUrl}
        data={data}
        isPreview={Boolean(input.preview)}
        selectedCategoryId={input.selectedCategoryId}
        isOpenNow={isOpenNow}
      />
    </main>
  );
}

export async function generateMetadata({ params, searchParams }: MenuPageProps) {
  const [{ slug }, rawSearchParams] = await Promise.all([params, searchParams]);
  // generatePublicMenuMetadata içinde notFound() çağrısı Next.js 15'te
  // metadata context'inde 500'e yol açabilir. Hata durumunda boş metadata dön;
  // asıl 404 kararını PublicMenuPage bileşeni verir.
  try {
    return await generatePublicMenuMetadata({
      businessSlugOrId: slug,
      lang: rawSearchParams.lang,
      theme: rawSearchParams.theme,
    });
  } catch {
    return {};
  }
}

export default async function PublicMenuPage({ params, searchParams }: MenuPageProps) {
  const [{ slug }, rawSearchParams] = await Promise.all([params, searchParams]);
  const data = await getPublicMenuPageData({ businessSlugOrId: slug }).catch(() => null);
  if (!data) notFound();
  const normalized = normalizeDisplayParams(rawSearchParams, {
    lang: data.presentation.defaultLang,
    theme: data.presentation.templateKey,
  });

  if (normalized.hasInvalidParams || hasLegacyBusinessPath(slug, data)) {
    redirect(
      buildCanonicalPublicMenuHref({
        data,
        lang: normalized.lang,
        theme: normalized.theme,
        src: normalized.src,
        preview: normalized.preview,
      }),
    );
  }

  return renderPublicMenuRoute({
    businessSlugOrId: slug,
    lang: normalized.lang,
    theme: normalized.theme,
    src: normalized.src,
    preview: normalized.preview,
    data,
  });
}

export function buildCanonicalPublicMenuHref(input: {
  data: NonNullable<Awaited<ReturnType<typeof getPublicMenuPageData>>>;
  lang?: string | null;
  theme?: BrandTheme | null;
  src?: string | null;
  preview?: boolean | null;
  categoryId?: string | null;
  itemId?: string | null;
}) {
  return buildBusinessMenuHref({
    business: input.data.business,
    categoryId: input.categoryId,
    itemId: input.itemId,
    lang: input.lang,
    theme: input.theme,
    src: input.src,
    preview: input.preview,
  });
}

export function hasLegacyBusinessPath(
  routeSlugOrId: string,
  data: NonNullable<Awaited<ReturnType<typeof getPublicMenuPageData>>>,
) {
  const normalizedRoute = routeSlugOrId.trim();
  const canonicalPath = resolveBusinessMenuPathKeyFromRecord(data.business);
  return !normalizedRoute || normalizedRoute !== canonicalPath;
}

