import type { Metadata } from 'next';
import { notFound, redirect } from 'next/navigation';
import { KarekodUreticiIstemcisi } from '@/src/ui/bolumler/karekod-uretici';
import { getBrandThemeDefinition, getBrandThemeOptions } from '@/src/lib/marka-temasi';
import { getPublicMenuPageData, getTranslationValue } from '@/src/lib/acik-menu-sayfasi';
import { appConfig } from '@/src/lib/ayarlar';
import { getImageBlurDataUrl } from '@/src/lib/gorsel-yer-tutucu';
import { copy } from '@/src/lib/ceviri';
import { encodeBusinessCode } from '@/src/lib/kisa-kod';
import { getQrAccessState } from '@/src/lib/karekod-erisimi';
import { buildMenuHref, buildQrHref, buildShortHref } from '@/src/lib/menu-baglantilari';
import { isUuid, normalizeDisplayParams } from '@/src/lib/yol-normalizasyonu';

type QrPageProps = {
  params: Promise<{ businessId: string }>;
  searchParams: Promise<{ lang?: string; theme?: string }>;
};

export async function generateMetadata({ params, searchParams }: QrPageProps): Promise<Metadata> {
  const [{ businessId }, rawSearchParams] = await Promise.all([params, searchParams]);

  if (!isUuid(businessId)) {
    notFound();
  }

  const data = await getPublicMenuPageData({ businessSlugOrId: businessId });

  if (!data) {
    notFound();
  }

  const normalized = normalizeDisplayParams(rawSearchParams, {
    lang: data.presentation.defaultLang,
    theme: data.presentation.templateKey,
  });
  const language = normalized.lang;

  const businessName =
    getTranslationValue({
      translations: data.translations,
      entityType: 'business',
      entityId: data.business.id,
      locale: language,
      field: 'name',
      fallback: data.business.name,
    }) ?? data.business.name;

  return {
    metadataBase: new URL(appConfig.siteUrl()),
    title: `${businessName} | Karekod Menu`,
    description: `QR menu assets for ${businessName}`,
    robots: {
      index: false,
      follow: false,
    },
  };
}

export default async function QrPage({ params, searchParams }: QrPageProps) {
  const [{ businessId }, rawSearchParams] = await Promise.all([params, searchParams]);

  if (!isUuid(businessId)) {
    notFound();
  }

  const access = await getQrAccessState(businessId);
  const data = await getPublicMenuPageData({ businessSlugOrId: businessId });

  if (!data) notFound();

  const normalized = normalizeDisplayParams(rawSearchParams, {
    lang: data.presentation.defaultLang,
    theme: data.presentation.templateKey,
  });
  const language = normalized.lang;
  const brandTheme = normalized.theme;
  const redirectTo = `/karekod/${businessId}?lang=${language}&theme=${brandTheme}`;

  if (!access.user) {
    redirect(`/giris?redirect=${encodeURIComponent(redirectTo)}`);
  }

  if (!access.canManage) {
    redirect(`/yasakli?from=${encodeURIComponent(redirectTo)}`);
  }

  if (normalized.hasInvalidParams) {
    redirect(
      buildQrHref({
        businessId,
        lang: language,
        theme: brandTheme,
      }),
    );
  }

  const businessName =
    getTranslationValue({
      translations: data.translations,
      entityType: 'business',
      entityId: data.business.id,
      locale: language,
      field: 'name',
      fallback: data.business.name,
    }) ?? data.business.name;

  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonicalUrl = `${siteUrl}${buildMenuHref({
    businessId,
    businessSlug: data.business.slug,
    businessPublicSlug: data.business.public_slug,
    lang: language,
    theme: brandTheme,
  })}`;
  const shortUrl = `${siteUrl}${buildShortHref({
    code: encodeBusinessCode(businessId),
    lang: language,
    theme: brandTheme,
  })}`;
  const mediaOptions = buildMediaOptions(data);
  const themeOptions = getBrandThemeOptions().map((option) => ({
    id: option.id,
    label: option.label[language],
    description: option.description[language],
    previewBackground: getBrandThemeDefinition(option.id).heroBackground,
    previewAccent: getBrandThemeDefinition(option.id).featuredAccent,
  }));
  const themeCatalog = {
    minimal: getBrandThemeDefinition('minimal'),
    bold: getBrandThemeDefinition('bold'),
    elegant: getBrandThemeDefinition('elegant'),
    'photo-heavy': getBrandThemeDefinition('photo-heavy'),
    'dark-modern': getBrandThemeDefinition('dark-modern'),
  } as const;
  const blurDataUrlByTheme = {
    minimal: getImageBlurDataUrl(themeCatalog.minimal),
    bold: getImageBlurDataUrl(themeCatalog.bold),
    elegant: getImageBlurDataUrl(themeCatalog.elegant),
    'photo-heavy': getImageBlurDataUrl(themeCatalog['photo-heavy']),
    'dark-modern': getImageBlurDataUrl(themeCatalog['dark-modern']),
  } as const;

  return (
    <KarekodUreticiIstemcisi
      lang={language}
      baseCopy={copy[language]}
      themeCatalog={themeCatalog}
      themeOptions={themeOptions}
      blurDataUrlByTheme={blurDataUrlByTheme}
      businessId={businessId}
      businessSlug={data.business.slug}
      businessPublicSlug={data.business.public_slug}
      businessName={businessName}
      logoUrl={data.media.logoUrl}
      canonicalUrl={canonicalUrl}
      shortUrl={shortUrl}
      initialPresentation={data.presentation}
      mediaOptions={mediaOptions}
    />
  );
}

function buildMediaOptions(data: NonNullable<Awaited<ReturnType<typeof getPublicMenuPageData>>>) {
  const seen = new Set<string>();
  const options: Array<{ id: string; url: string; label: string }> = [];

  const pushOption = (id: string, url: string | null | undefined, label: string) => {
    const normalized = url?.trim();
    if (!normalized || seen.has(normalized)) return;
    seen.add(normalized);
    options.push({ id, url: normalized, label });
  };

  pushOption('presentation-logo', data.presentation.logoUrl, 'presentation logo');
  pushOption('presentation-cover', data.presentation.coverUrl, 'presentation cover');
  pushOption('presentation-background', data.presentation.backgroundUrl, 'presentation background');
  pushOption('logo', data.media.logoUrl, 'logo');
  pushOption('cover', data.media.coverUrl, 'cover');

  data.media.gallery.forEach((entry, index) => {
    pushOption(entry.id || `gallery-${index + 1}`, entry.url_large || entry.url_thumb || entry.url, `gallery ${index + 1}`);
  });

  return options;
}
