/* eslint-disable @next/next/no-img-element */
'use client';

import dynamic from 'next/dynamic';
import { useEffect, useMemo, useState, type ReactNode } from 'react';
import type { BrandTheme, BrandThemeDefinition } from '@/src/lib/marka-temasi';
import { formatCurrency } from '@/src/lib/bicimlendirme';
import type { AppLang, MenuCopy } from '@/src/lib/ceviri';
import { appendMediaVersion } from '@/src/lib/medya-adresi';
import { buildMenuHref, buildShortHref } from '@/src/lib/menu-baglantilari';
import { getPresentationViewModel } from '@/src/lib/sunum-gorunumu';
import type { ResolvedPresentationRecord } from '@/src/lib/sunum-ayarlari';
import type { DefaultLang, PresentationSettings } from '@/src/lib/sablonlar/sablon-calisma';

type MediaOption = {
  id: string;
  url: string;
  label: string;
};

type Props = {
  lang: AppLang;
  baseCopy: MenuCopy;
  themeCatalog: Record<BrandTheme, BrandThemeDefinition>;
  themeOptions: Array<{
    id: BrandTheme;
    label: string;
    description: string;
    previewBackground: string;
    previewAccent: string;
  }>;
  blurDataUrlByTheme: Record<BrandTheme, string>;
  businessId: string;
  businessSlug?: string | null;
  businessPublicSlug?: string | null;
  businessName: string;
  logoUrl: string | null;
  canonicalUrl: string;
  shortUrl: string;
  initialPresentation: ResolvedPresentationRecord;
  mediaOptions: MediaOption[];
};

type DraftState = {
  defaultLang: DefaultLang;
  templateKey: BrandTheme;
  settings: PresentationSettings;
  logoUrl: string | null;
  coverUrl: string | null;
  backgroundUrl: string | null;
};

const KarekodMarkaPaneli = dynamic(
  () => import('@/src/ui/bolumler/karekod-marka-paneli').then((module) => module.KarekodMarkaPaneli),
  {
    loading: () => (
      <section className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
        <div className="space-y-6">
          <div className="h-72 rounded-[30px] border border-border bg-card shadow-yd1" />
          <div className="h-[32rem] rounded-[30px] border border-border bg-card shadow-yd1" />
        </div>
        <div className="h-[32rem] rounded-[30px] border border-border bg-card shadow-yd1" />
      </section>
    ),
  },
);

const brandingCopy = {
  tr: {
    studio: 'Karekod Tasarim Kiti',
    studioBody: 'Bu ekran yalnizca sunum, karekod ve acik baglanti ayarlarini kaydeder. Menu CRUD panelde kalir.',
    qrTab: 'Karekod ve Baglantilar',
    brandingTab: 'Sablon ve Marka',
    save: 'Kaydet',
    saving: 'Kaydediliyor...',
    saved: 'Marka ayarlari kaydedildi.',
    reset: 'Kayitli ayarlara don',
    resetDone: 'Yerel degisiklikler geri alindi.',
    saveError: 'Kayit sirasinda hata olustu.',
    uploadError: 'Gorsel yukleme basarisiz.',
    unsaved: 'Kaydedilmemis degisiklik var.',
    savedState: 'Kayitli varsayilan',
    previewLink: 'Onizleme baglantisi',
    copyPreview: 'Onizleme baglantisini kopyala',
    openPreview: 'Onizleme ac',
    uploadLogo: 'Logo yukle',
    uploadCover: 'Kapak yukle',
    uploadBackground: 'Arka plan yukle',
    useExisting: 'Mevcut gorseli kullan',
    assets: 'Gorsel varliklar',
    preview: 'Canli onizleme',
    backgroundMode: 'Arka plan modu',
    headerLayout: 'Baslik yerlesimi',
    cardStyle: 'Kart yogunlugu',
    fontScale: 'Yazi olcegi',
    toggles: 'Goster / gizle',
    solid: 'Duz',
    gradient: 'Gradient',
    image: 'Gorsel',
    left: 'Sola hizali',
    centered: 'Ortali',
    compact: 'Kompakt',
    comfortable: 'Rahat',
    normal: 'Normal',
    large: 'Buyuk',
    featured: 'One cikanlar',
    tags: 'Etiketler',
    allergens: 'Diyet etiketleri',
    currency: 'Para simgesi',
    updated: 'Guncellenme tarihi',
    publicLink: 'Acik menu baglantisi',
    shortLink: 'Kisa baglanti',
    copyPublic: 'Acik baglantiyi kopyala',
    copyShort: 'Kisa linki kopyala',
    downloadPng: 'PNG indir',
    downloadSvg: 'SVG indir',
    copyOk: 'Link kopyalandi.',
    chooseTemplate: 'Template sec',
    chooseLang: 'Dil sec',
    accent: 'Accent renk',
    customHex: 'Ozel renk',
    backgroundImage: 'Arka plan gorseli',
    coverImage: 'Kapak gorseli',
    logoImage: 'Logo',
    remove: 'Kaldir',
    qrTarget: 'QR hedefi',
    useShort: 'Kisa baglanti kullan',
    fallbackPreview: 'Marka sunumu',
  },
  en: {
    studio: 'Karekod Design Kit',
    studioBody: 'This screen only saves presentation, karekod and public link settings. Menu CRUD remains in the panel.',
    qrTab: 'QR and Links',
    brandingTab: 'Sablon ve Marka',
    save: 'Save',
    saving: 'Saving...',
    saved: 'Marka ayarlari kaydedildi.',
    reset: 'Kayitli varsayilanlara sifirla',
    resetDone: 'Local changes were reverted.',
    saveError: 'Save failed.',
    uploadError: 'Image upload failed.',
    unsaved: 'You have unsaved changes.',
    savedState: 'Saved default',
    previewLink: 'Onizleme baglantisi',
    copyPreview: 'Onizleme baglantisini kopyala',
    openPreview: 'Onizleme ac',
    uploadLogo: 'Upload logo',
    uploadCover: 'Upload cover',
    uploadBackground: 'Upload background',
    useExisting: 'Use existing asset',
    assets: 'Media assets',
    preview: 'Live preview',
    backgroundMode: 'Background mode',
    headerLayout: 'Header layout',
    cardStyle: 'Card density',
    fontScale: 'Font scale',
    toggles: 'Show / hide',
    solid: 'Solid',
    gradient: 'Gradient',
    image: 'Image',
    left: 'Left aligned',
    centered: 'Centered',
    compact: 'Compact',
    comfortable: 'Comfortable',
    normal: 'Normal',
    large: 'Large',
    featured: 'Featured',
    tags: 'Tags',
    allergens: 'Dietary labels',
    currency: 'Currency symbol',
    updated: 'Last updated',
    publicLink: 'Acik menu baglantisi',
    shortLink: 'Kisa baglanti',
    copyPublic: 'Copy public link',
    copyShort: 'Copy short link',
    downloadPng: 'Download PNG',
    downloadSvg: 'Download SVG',
    copyOk: 'Link copied.',
    chooseTemplate: 'Sablon sec',
    chooseLang: 'Choose language',
    accent: 'Vurgu rengi',
    customHex: 'Custom color',
    backgroundImage: 'Background image',
    coverImage: 'Cover image',
    logoImage: 'Logo',
    remove: 'Remove',
    qrTarget: 'QR target',
    useShort: 'Use short link',
    fallbackPreview: 'Brand presentation',
  },
} as const;

export function KarekodUreticiIstemcisi({
  lang,
  baseCopy,
  themeCatalog,
  themeOptions,
  blurDataUrlByTheme,
  businessId,
  businessSlug,
  businessPublicSlug,
  businessName,
  logoUrl,
  canonicalUrl,
  shortUrl,
  initialPresentation,
  mediaOptions,
}: Props) {
  const labels = brandingCopy[lang];
  const siteUrl = useMemo(() => new URL(canonicalUrl).origin, [canonicalUrl]);
  const shortCode = useMemo(() => new URL(shortUrl).pathname.split('/').pop() ?? '', [shortUrl]);
  const initialDraft = useMemo<DraftState>(
    () => ({
      defaultLang: initialPresentation.defaultLang,
      templateKey: initialPresentation.templateKey,
      settings: initialPresentation.settings,
      logoUrl: initialPresentation.logoUrl ?? logoUrl,
      coverUrl: initialPresentation.coverUrl ?? null,
      backgroundUrl: initialPresentation.backgroundUrl ?? null,
    }),
    [initialPresentation, logoUrl],
  );
  const [activeTab, setActiveTab] = useState<'qr' | 'branding'>('qr');
  const [draft, setDraft] = useState<DraftState>(initialDraft);
  const [savedDraft, setSavedDraft] = useState<DraftState>(initialDraft);
  const [savedUpdatedAt, setSavedUpdatedAt] = useState<string | null>(initialPresentation.updatedAt ?? null);
  const [qrSvg, setQrSvg] = useState('');
  const [qrPng, setQrPng] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [isUploading, setIsUploading] = useState<'logo' | 'cover' | 'background' | null>(null);
  const [showShortLink, setShowShortLink] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const effectivePresentation: ResolvedPresentationRecord = {
    ...initialPresentation,
    defaultLang: draft.defaultLang,
    templateKey: draft.templateKey,
    settings: draft.settings,
    logoUrl: draft.logoUrl,
    coverUrl: draft.coverUrl,
    backgroundUrl: draft.backgroundUrl,
  };
  const themeDefinition = themeCatalog[draft.templateKey];
  const presentationView = getPresentationViewModel(
    effectivePresentation,
    draft.templateKey,
    themeDefinition,
  );
  const blurDataUrl = blurDataUrlByTheme[draft.templateKey];
  const hasUnsavedChanges = serializeDraft(draft) !== serializeDraft(savedDraft);
  const publicHref = buildMenuHref({
    businessId,
    businessSlug,
    businessPublicSlug,
    lang: draft.defaultLang,
    theme: draft.templateKey,
  });
  const previewHref = buildMenuHref({
    businessId,
    businessSlug,
    businessPublicSlug,
    lang: draft.defaultLang,
    theme: draft.templateKey,
    preview: true,
  });
  const shortHref = buildShortHref({
    code: shortCode,
    lang: draft.defaultLang,
    theme: draft.templateKey,
  });
  const publicLink = `${siteUrl}${publicHref}`;
  const previewLink = `${siteUrl}${previewHref}`;
  const shortLink = `${siteUrl}${shortHref}`;
  const qrTarget = showShortLink ? shortLink : publicLink;
  const previewHeroImageUrl = appendMediaVersion(draft.backgroundUrl || draft.coverUrl, savedUpdatedAt);
  const previewCoverUrl = appendMediaVersion(draft.coverUrl, savedUpdatedAt);
  const previewLogoUrl = appendMediaVersion(draft.logoUrl, savedUpdatedAt);

  useEffect(() => {
    let alive = true;

    async function generateQr() {
      const qrCode = await import('qrcode');
      const [svg, png] = await Promise.all([
        qrCode.toString(qrTarget, {
          errorCorrectionLevel: 'H',
          margin: 1,
          type: 'svg',
          color: {
            dark: themeDefinition.brandQrDark,
            light: '#ffffff',
          },
        }),
        qrCode.toDataURL(qrTarget, {
          errorCorrectionLevel: 'H',
          margin: 1,
          width: 1280,
          color: {
            dark: themeDefinition.brandQrDark,
            light: '#ffffff',
          },
        }),
      ]);

      if (!alive) return;
      setQrSvg(svg);
      setQrPng(png);
    }

    void generateQr().catch(() => {
      if (!alive) return;
      setError(labels.saveError);
    });

    return () => {
      alive = false;
    };
  }, [labels.saveError, qrTarget, themeDefinition.brandQrDark]);

  useEffect(() => {
    if (!hasUnsavedChanges) return;

    const handleBeforeUnload = (event: BeforeUnloadEvent) => {
      event.preventDefault();
      event.returnValue = '';
    };

    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
    };
  }, [hasUnsavedChanges]);

  function updateSettings(patch: Partial<PresentationSettings>) {
    setDraft((current) => ({
      ...current,
      settings: {
        ...current.settings,
        ...patch,
      },
    }));
  }

  async function handleCopy(value: string) {
    try {
      await navigator.clipboard.writeText(value);
      setNotice(labels.copyOk);
      setError(null);
    } catch {
      setError(labels.saveError);
    }
  }

  async function handleSave() {
    setIsSaving(true);
    setNotice(null);
    setError(null);

    try {
      const response = await fetch('/sunucu/sunum-ayarlari', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          businessId,
          defaultLang: draft.defaultLang,
          templateKey: draft.templateKey,
          settings: draft.settings,
          logoUrl: draft.logoUrl,
          coverUrl: draft.coverUrl,
          backgroundUrl: draft.backgroundUrl,
        }),
      });

      if (!response.ok) {
        throw new Error('save_failed');
      }

      const payload = (await response.json().catch(() => null)) as { data?: { updated_at?: string | null } } | null;
      const nextUpdatedAt = payload?.data?.updated_at ?? new Date().toISOString();
      setSavedDraft(draft);
      setSavedUpdatedAt(nextUpdatedAt);
      setNotice(labels.saved);
    } catch {
      setError(labels.saveError);
    } finally {
      setIsSaving(false);
    }
  }

  async function handleUpload(type: 'logo' | 'cover' | 'background', file: File | null) {
    if (!file) return;

    setIsUploading(type);
    setNotice(null);
    setError(null);

    try {
      const formData = new FormData();
      formData.set('businessId', businessId);
      formData.set('type', type);
      formData.set('file', file);

      const response = await fetch('/sunucu/medya/yukleme', {
        method: 'POST',
        body: formData,
      });
      const payload = (await response.json().catch(() => null)) as { data?: { url?: string } } | null;

      if (!response.ok || !payload?.data?.url) {
        throw new Error('upload_failed');
      }

      const nextUrl = payload.data.url;
      setDraft((current) => ({
        ...current,
        logoUrl: type === 'logo' ? nextUrl : current.logoUrl,
        coverUrl: type === 'cover' ? nextUrl : current.coverUrl,
        backgroundUrl: type === 'background' ? nextUrl : current.backgroundUrl,
      }));
      setNotice(labels.saved);
    } catch {
      setError(labels.uploadError);
    } finally {
      setIsUploading(null);
    }
  }

  function downloadFile(url: string, filename: string) {
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
  }

  function handleReset() {
    setDraft(savedDraft);
    setNotice(labels.resetDone);
    setError(null);
  }

  function handleExternalOpen(url: string) {
    if (hasUnsavedChanges && !window.confirm(labels.unsaved)) {
      return;
    }
    window.open(url, '_blank', 'noopener,noreferrer');
  }

  return (
    <div data-testid="qr-studio" className="space-y-6 rounded-[36px] p-3 pb-10 sm:p-4">
      <section className="overflow-hidden rounded-[32px] border border-border bg-card shadow-yd2">
        <div className="grid gap-6 p-6 sm:p-8 xl:grid-cols-[1.15fr_0.85fr]">
          <div className="space-y-4">
            <div className="flex flex-wrap items-center gap-2">
              <span className="rounded-full border border-primary/15 bg-primary/8 px-4 py-2 text-[11px] font-black uppercase tracking-[0.24em] text-primary">
                {labels.studio}
              </span>
              <span className="rounded-full border border-border bg-bg px-4 py-2 text-[11px] font-black uppercase tracking-[0.2em] text-textStrong">
                {businessName}
              </span>
            </div>
            <h1 className="text-3xl font-black tracking-[-0.04em] text-textStrong sm:text-5xl">
              {baseCopy.qrTitle}
            </h1>
            <p className="max-w-2xl text-sm leading-7 text-text">{labels.studioBody}</p>
            <div
              className="grid gap-3"
              role="tablist"
              aria-label={labels.studio}
            >
              <SegmentedButton active={activeTab === 'qr'} onClick={() => setActiveTab('qr')}>
                {labels.qrTab}
              </SegmentedButton>
              <SegmentedButton active={activeTab === 'branding'} onClick={() => setActiveTab('branding')}>
                {labels.brandingTab}
              </SegmentedButton>
            </div>
            <div className="grid gap-3">
              <ActionButton onClick={handleSave} disabled={isSaving}>
                {isSaving ? labels.saving : labels.save}
              </ActionButton>
              <ActionButton secondary onClick={handleReset} disabled={!hasUnsavedChanges || isSaving}>
                {labels.reset}
              </ActionButton>
              <button
                type="button"
                onClick={() => handleExternalOpen(previewLink)}
                className="inline-flex w-full touch-manipulation items-center justify-center rounded-[20px] border border-border bg-bg px-4 py-4 text-sm font-black leading-none text-textStrong transition hover:border-primary/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/35"
                style={{ minHeight: 48, minWidth: 48 }}
              >
                {labels.openPreview}
              </button>
            </div>
            <div className="flex flex-wrap items-center gap-3 text-sm">
              <span className="rounded-full border border-border bg-bg px-4 py-2 font-semibold text-textStrong">
                {labels.savedState}: {savedDraft.templateKey} / {savedDraft.defaultLang.toUpperCase()}
              </span>
              {hasUnsavedChanges ? (
                <span className="rounded-full border border-amber-400/40 bg-amber-50 px-4 py-2 font-semibold text-amber-800">
                  {labels.unsaved}
                </span>
              ) : null}
            </div>
            {notice ? <p className="text-sm font-semibold text-emerald-700">{notice}</p> : null}
            {error ? <p className="text-sm font-semibold text-red-700">{error}</p> : null}
          </div>

          <div
            className="overflow-hidden rounded-[30px] border border-border p-4 shadow-yd1"
            style={{ backgroundImage: themeDefinition.qrPanelBackground }}
          >
            <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.preview}</p>
            <div
              className={`mt-4 overflow-hidden rounded-[28px] border border-border bg-card ${presentationView.fontScaleClassName}`}
              style={{ backgroundImage: themeDefinition.previewSurface }}
            >
              <div className="relative min-h-[220px] overflow-hidden p-5 text-white" style={presentationView.heroStyle}>
                {previewHeroImageUrl ? (
                  <img
                    src={previewHeroImageUrl}
                    alt={businessName}
                    loading="eager"
                    decoding="async"
                    data-blur={blurDataUrl}
                    className="absolute inset-0 h-full w-full object-cover opacity-25"
                  />
                ) : null}
                <div className={`relative z-10 flex h-full flex-col justify-between gap-5 ${presentationView.headerAlignClassName}`}>
                  <div className="space-y-3">
                    <span className="rounded-full border border-white/20 bg-white/10 px-3 py-1 text-[11px] font-black uppercase tracking-[0.2em]">
                      {themeDefinition.label[draft.defaultLang]}
                    </span>
                    <h2 className="text-3xl font-black tracking-[-0.03em]">{businessName}</h2>
                    <p className="text-sm text-white/84">{labels.fallbackPreview}</p>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {presentationView.showFeatured ? <PreviewBadge>Featured</PreviewBadge> : null}
                    {presentationView.showTags ? <PreviewBadge>#chef</PreviewBadge> : null}
                    {presentationView.showAllergens ? <PreviewBadge>vegan</PreviewBadge> : null}
                  </div>
                </div>
              </div>
              <div className={`grid gap-3 p-4 ${presentationView.isPhotoHeavy ? 'md:grid-cols-2' : ''}`}>
                <PreviewItem
                  imageUrl={previewCoverUrl}
                  blurDataUrl={blurDataUrl}
                  title={businessName}
                  subtitle={themeDefinition.description[draft.defaultLang]}
                  price={formatCurrency(56000, draft.defaultLang, 'TRY', draft.settings.showCurrencySymbol)}
                  dense={presentationView.denseCardClassName}
                  dark={presentationView.isDarkSurface}
                />
                <PreviewItem
                  imageUrl={previewLogoUrl}
                  blurDataUrl={blurDataUrl}
                  title={draft.defaultLang === 'tr' ? 'Imza tabak' : 'Signature plate'}
                subtitle={draft.defaultLang === 'tr' ? 'Sablon ve marka onizlemesi' : 'Template and branding preview'}
                  price={formatCurrency(42000, draft.defaultLang, 'TRY', draft.settings.showCurrencySymbol)}
                  dense={presentationView.denseCardClassName}
                  dark={presentationView.isDarkSurface}
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {activeTab === 'qr' ? (
        <section className="grid gap-6 xl:grid-cols-[0.8fr_1.2fr]">
          <div className="rounded-[30px] border border-border bg-card p-5 shadow-yd1">
            <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.qrTarget}</p>
            <label className="mt-4 flex min-h-12 touch-manipulation items-center gap-3 rounded-[20px] border border-border bg-bg px-4 py-3 text-sm font-semibold text-textStrong">
              <input
                type="checkbox"
                checked={showShortLink}
                onChange={(event) => setShowShortLink(event.target.checked)}
                className="h-4 w-4 accent-primary"
                aria-label={labels.useShort}
              />
              {labels.useShort}
            </label>
            <div className="mt-5 overflow-hidden rounded-[28px] border border-border bg-white p-5">
              {qrSvg ? (
                <div className="mx-auto w-full max-w-[320px]" dangerouslySetInnerHTML={{ __html: qrSvg }} />
              ) : (
                <div className="mx-auto aspect-square w-full max-w-[320px] rounded-[24px] bg-cardAlt" />
              )}
            </div>
            {previewLogoUrl ? (
              <div className="mt-4 flex items-center gap-3 rounded-2xl border border-border bg-bg px-4 py-3">
                <div className="relative h-12 w-12 overflow-hidden rounded-2xl">
                  <img src={previewLogoUrl} alt={businessName} loading="lazy" decoding="async" className="h-full w-full object-cover" />
                </div>
                <div>
                  <p className="text-sm font-black text-textStrong">{businessName}</p>
                  <p className="text-xs text-muted">{labels.logoImage}</p>
                </div>
              </div>
            ) : null}
          </div>

          <div className="space-y-4">
            <LinkCard title={labels.previewLink} value={previewLink} actionLabel={labels.copyPreview} onAction={() => handleCopy(previewLink)} />
            <LinkCard title={labels.publicLink} value={publicLink} actionLabel={labels.copyPublic} onAction={() => handleCopy(publicLink)} />
            <LinkCard title={labels.shortLink} value={shortLink} actionLabel={labels.copyShort} onAction={() => handleCopy(shortLink)} />
            <div className="grid gap-3">
              <ActionButton onClick={() => qrPng && downloadFile(qrPng, `${businessId}-menu-qr.png`)}>
                {labels.downloadPng}
              </ActionButton>
              <ActionButton
                secondary
                onClick={() =>
                  qrSvg &&
                  downloadFile(
                    `data:image/svg+xml;charset=utf-8,${encodeURIComponent(qrSvg)}`,
                    `${businessId}-menu-qr.svg`,
                  )
                }
              >
                {labels.downloadSvg}
              </ActionButton>
            </div>
          </div>
        </section>
      ) : (
        <KarekodMarkaPaneli
          lang={lang}
          labels={labels}
          baseCopy={baseCopy}
          themeOptions={themeOptions}
          draft={draft}
          isUploading={isUploading}
          mediaOptions={mediaOptions}
          onTemplateChange={(value) => setDraft((current) => ({ ...current, templateKey: value }))}
          onDefaultLangChange={(value) => setDraft((current) => ({ ...current, defaultLang: value }))}
          onSettingsPatch={updateSettings}
          onUpload={handleUpload}
          onSetMediaUrl={(type, url) =>
            setDraft((current) => ({
              ...current,
              logoUrl: type === 'logo' ? url : current.logoUrl,
              coverUrl: type === 'cover' ? url : current.coverUrl,
              backgroundUrl: type === 'background' ? url : current.backgroundUrl,
            }))
          }
        />
      )}
    </div>
  );
}

function SegmentedButton({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      role="tab"
      aria-selected={active}
      className={`inline-flex w-full touch-manipulation items-center justify-center rounded-[20px] border px-4 py-4 text-sm font-black uppercase tracking-[0.14em] leading-none transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/35 ${
        active ? 'border-primary bg-primary text-white' : 'border-border bg-bg text-textStrong hover:border-primary/30'
      }`}
      style={{ minHeight: 48, minWidth: 48 }}
    >
      {children}
    </button>
  );
}

function ActionButton({
  children,
  onClick,
  disabled,
  secondary = false,
}: {
  children: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  secondary?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={`inline-flex w-full touch-manipulation items-center justify-center rounded-[20px] px-4 py-4 text-sm font-black leading-none transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/35 disabled:cursor-not-allowed disabled:opacity-60 ${
        secondary
          ? 'border border-border bg-bg text-textStrong hover:border-primary/30'
          : 'bg-primary text-white hover:opacity-92'
      }`}
      style={{ minHeight: 48, minWidth: 48 }}
    >
      {children}
    </button>
  );
}

function LinkCard({
  title,
  value,
  actionLabel,
  onAction,
}: {
  title: string;
  value: string;
  actionLabel: string;
  onAction: () => void;
}) {
  return (
    <div className="rounded-[28px] border border-border bg-card p-5 shadow-yd1">
      <p className="text-xs font-black uppercase tracking-[0.2em] text-muted">{title}</p>
      <p className="mt-3 break-all rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong">
        {value}
      </p>
      <div className="mt-4">
        <ActionButton secondary onClick={onAction}>
          {actionLabel}
        </ActionButton>
      </div>
    </div>
  );
}


function PreviewItem({
  imageUrl,
  blurDataUrl,
  title,
  subtitle,
  price,
  dense,
  dark,
}: {
  imageUrl: string | null;
  blurDataUrl: string;
  title: string;
  subtitle: string;
  price: string;
  dense: string;
  dark: boolean;
}) {
  return (
    <div
      className={`overflow-hidden rounded-[24px] border ${dark ? 'border-slate-700 bg-slate-900 text-white' : 'border-border bg-card'} ${dense}`}
    >
      <div className="grid gap-3 sm:grid-cols-[96px_1fr]">
        <div className="relative h-24 overflow-hidden rounded-[18px] bg-cardAlt">
          {imageUrl ? (
            <img
              src={imageUrl}
              alt={title}
              loading="lazy"
              decoding="async"
              data-blur={blurDataUrl}
              className="h-full w-full object-cover"
            />
          ) : null}
        </div>
        <div className="space-y-2">
          <p className={`text-lg font-black ${dark ? 'text-white' : 'text-textStrong'}`}>{title}</p>
          <p className={`text-sm ${dark ? 'text-slate-300' : 'text-muted'}`}>{subtitle}</p>
          <p className={`text-sm font-black ${dark ? 'text-cyan-300' : 'text-primary'}`}>{price}</p>
        </div>
      </div>
    </div>
  );
}

function PreviewBadge({ children }: { children: ReactNode }) {
  return (
    <span className="rounded-full border border-white/15 bg-white/10 px-3 py-1 text-xs font-black uppercase tracking-[0.16em] text-white">
      {children}
    </span>
  );
}

function serializeDraft(draft: DraftState) {
  return JSON.stringify({
    defaultLang: draft.defaultLang,
    templateKey: draft.templateKey,
    settings: draft.settings,
    logoUrl: draft.logoUrl,
    coverUrl: draft.coverUrl,
    backgroundUrl: draft.backgroundUrl,
  });
}

