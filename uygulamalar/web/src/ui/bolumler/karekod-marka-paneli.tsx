/* eslint-disable @next/next/no-img-element */
'use client';

import type { ReactNode } from 'react';
import type { BrandTheme } from '@/src/lib/marka-temasi';
import type { DefaultLang, PresentationSettings } from '@/src/lib/sablonlar/sablon-calisma';

type MediaOption = {
  id: string;
  url: string;
  label: string;
};

type DraftState = {
  defaultLang: DefaultLang;
  templateKey: BrandTheme;
  settings: PresentationSettings;
  logoUrl: string | null;
  coverUrl: string | null;
  backgroundUrl: string | null;
};

type Labels = {
  chooseTemplate: string;
  chooseLang: string;
  backgroundMode: string;
  headerLayout: string;
  cardStyle: string;
  fontScale: string;
  toggles: string;
  solid: string;
  gradient: string;
  image: string;
  left: string;
  centered: string;
  compact: string;
  comfortable: string;
  normal: string;
  large: string;
  featured: string;
  tags: string;
  allergens: string;
  currency: string;
  updated: string;
  accent: string;
  customHex: string;
  assets: string;
  logoImage: string;
  coverImage: string;
  backgroundImage: string;
  uploadLogo: string;
  uploadCover: string;
  uploadBackground: string;
  remove: string;
  useExisting: string;
};

type BaseCopy = {
  languageTr: string;
  languageEn: string;
};

type Props = {
  lang: 'tr' | 'en';
  labels: Labels;
  baseCopy: BaseCopy;
  themeOptions: Array<{
    id: BrandTheme;
    label: string;
    description: string;
    previewBackground: string;
    previewAccent: string;
  }>;
  draft: DraftState;
  isUploading: 'logo' | 'cover' | 'background' | null;
  mediaOptions: MediaOption[];
  onTemplateChange: (value: BrandTheme) => void;
  onDefaultLangChange: (value: DefaultLang) => void;
  onSettingsPatch: (patch: Partial<PresentationSettings>) => void;
  onUpload: (type: 'logo' | 'cover' | 'background', file: File | null) => void;
  onSetMediaUrl: (type: 'logo' | 'cover' | 'background', url: string | null) => void;
};

const accentOptions = [
  { id: 'brand', label: { tr: 'Marka', en: 'Brand' } },
  { id: 'slate', label: { tr: 'Koyu Gri', en: 'Slate' } },
  { id: 'forest', label: { tr: 'Orman', en: 'Forest' } },
  { id: 'amber', label: { tr: 'Amber', en: 'Amber' } },
  { id: 'rose', label: { tr: 'Gül', en: 'Rose' } },
  { id: 'custom', label: { tr: 'Özel', en: 'Custom' } },
] as const;

export function KarekodMarkaPaneli({
  lang,
  labels,
  baseCopy,
  themeOptions,
  draft,
  isUploading,
  mediaOptions,
  onTemplateChange,
  onDefaultLangChange,
  onSettingsPatch,
  onUpload,
  onSetMediaUrl,
}: Props) {
  return (
    <section className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
      <div className="space-y-6">
        <div className="rounded-[30px] border border-border bg-card p-5 shadow-yd1">
          <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.chooseTemplate}</p>
          <div className="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {themeOptions.map((option) => {
              const active = draft.templateKey === option.id;
              return (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => onTemplateChange(option.id)}
                  aria-pressed={active}
                  aria-label={`${labels.chooseTemplate}: ${option.label}`}
                  className={`min-h-11 rounded-[24px] border p-4 text-left transition focus-visible:outline-hidden ${
                    active ? 'border-primary bg-primary/6 shadow-yd1' : 'border-border bg-bg hover:border-primary/25'
                  }`}
                  style={{ height: 44, minHeight: 44 }}
                >
                  <div
                    aria-hidden="true"
                    className="mb-4 overflow-hidden rounded-[18px] border border-border/60 p-3"
                    style={{ backgroundImage: option.previewBackground }}
                  >
                    <div className="space-y-2">
                      <div className="h-2.5 w-20 rounded-full bg-white/80" />
                      <div className="grid gap-2 sm:grid-cols-2">
                        <div className="rounded-[14px] border border-white/20 bg-white/15 p-2">
                          <div className="h-12 rounded-[10px]" style={{ backgroundImage: option.previewAccent }} />
                        </div>
                        <div className="rounded-[14px] border border-white/20 bg-white/12 p-2">
                          <div className="h-12 rounded-[10px] bg-white/20" />
                        </div>
                      </div>
                    </div>
                  </div>
                  <p className="text-sm font-black text-textStrong">{option.label}</p>
                  <p className="mt-2 text-sm leading-6 text-muted">{option.description}</p>
                </button>
              );
            })}
          </div>
        </div>

        <div className="rounded-[30px] border border-border bg-card p-5 shadow-yd1">
          <div className="grid gap-5 md:grid-cols-2">
            <SettingGroup label={labels.chooseLang}>
              <OptionRow>
                <SegmentedButton active={draft.defaultLang === 'tr'} onClick={() => onDefaultLangChange('tr')}>
                  {baseCopy.languageTr}
                </SegmentedButton>
                <SegmentedButton active={draft.defaultLang === 'en'} onClick={() => onDefaultLangChange('en')}>
                  {baseCopy.languageEn}
                </SegmentedButton>
              </OptionRow>
            </SettingGroup>

            <SettingGroup label={labels.backgroundMode}>
              <OptionRow>
                <SegmentedButton
                  active={draft.settings.backgroundMode === 'solid'}
                  onClick={() => onSettingsPatch({ backgroundMode: 'solid' })}
                >
                  {labels.solid}
                </SegmentedButton>
                <SegmentedButton
                  active={draft.settings.backgroundMode === 'gradient'}
                  onClick={() => onSettingsPatch({ backgroundMode: 'gradient' })}
                >
                  {labels.gradient}
                </SegmentedButton>
                <SegmentedButton
                  active={draft.settings.backgroundMode === 'image'}
                  onClick={() => onSettingsPatch({ backgroundMode: 'image' })}
                >
                  {labels.image}
                </SegmentedButton>
              </OptionRow>
            </SettingGroup>

            <SettingGroup label={labels.headerLayout}>
              <OptionRow>
                <SegmentedButton
                  active={draft.settings.headerLayout === 'left'}
                  onClick={() => onSettingsPatch({ headerLayout: 'left' })}
                >
                  {labels.left}
                </SegmentedButton>
                <SegmentedButton
                  active={draft.settings.headerLayout === 'centered'}
                  onClick={() => onSettingsPatch({ headerLayout: 'centered' })}
                >
                  {labels.centered}
                </SegmentedButton>
              </OptionRow>
            </SettingGroup>

            <SettingGroup label={labels.cardStyle}>
              <OptionRow>
                <SegmentedButton
                  active={draft.settings.cardStyle === 'compact'}
                  onClick={() => onSettingsPatch({ cardStyle: 'compact' })}
                >
                  {labels.compact}
                </SegmentedButton>
                <SegmentedButton
                  active={draft.settings.cardStyle === 'comfortable'}
                  onClick={() => onSettingsPatch({ cardStyle: 'comfortable' })}
                >
                  {labels.comfortable}
                </SegmentedButton>
              </OptionRow>
            </SettingGroup>

            <SettingGroup label={labels.fontScale}>
              <OptionRow>
                <SegmentedButton
                  active={draft.settings.fontScale === 'normal'}
                  onClick={() => onSettingsPatch({ fontScale: 'normal' })}
                >
                  {labels.normal}
                </SegmentedButton>
                <SegmentedButton
                  active={draft.settings.fontScale === 'large'}
                  onClick={() => onSettingsPatch({ fontScale: 'large' })}
                >
                  {labels.large}
                </SegmentedButton>
              </OptionRow>
            </SettingGroup>

            <SettingGroup label={labels.accent}>
              <div className="grid gap-2 sm:grid-cols-3">
                {accentOptions.map((option) => (
                  <SegmentedButton
                    key={option.id}
                    active={draft.settings.accentPreset === option.id}
                    onClick={() => onSettingsPatch({ accentPreset: option.id })}
                  >
                    {option.label[lang]}
                  </SegmentedButton>
                ))}
              </div>
              {draft.settings.accentPreset === 'custom' ? (
                <input
                  value={draft.settings.accentHex ?? '#7f1d1d'}
                  onChange={(event) => onSettingsPatch({ accentHex: event.target.value })}
                  aria-label={labels.customHex}
                  className="mt-3 min-h-11 w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong outline-hidden transition focus:border-primary"
                />
              ) : null}
            </SettingGroup>

            <SettingGroup label={labels.toggles} className="md:col-span-2">
              <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
                <ToggleCard label={labels.featured} checked={draft.settings.showFeatured} onChange={(checked) => onSettingsPatch({ showFeatured: checked })} />
                <ToggleCard label={labels.tags} checked={draft.settings.showTags} onChange={(checked) => onSettingsPatch({ showTags: checked })} />
                <ToggleCard label={labels.allergens} checked={draft.settings.showAllergens} onChange={(checked) => onSettingsPatch({ showAllergens: checked })} />
                <ToggleCard label={labels.currency} checked={draft.settings.showCurrencySymbol} onChange={(checked) => onSettingsPatch({ showCurrencySymbol: checked })} />
                <ToggleCard label={labels.updated} checked={draft.settings.showLastUpdated} onChange={(checked) => onSettingsPatch({ showLastUpdated: checked })} />
              </div>
            </SettingGroup>
          </div>
        </div>
      </div>

      <div className="space-y-4">
        <div className="rounded-[30px] border border-border bg-card p-5 shadow-yd1">
          <p className="text-xs font-black uppercase tracking-[0.24em] text-muted">{labels.assets}</p>
          <div className="mt-4 space-y-4">
            <MediaField
              testId="logo"
              title={labels.logoImage}
              value={draft.logoUrl}
              uploadLabel={labels.uploadLogo}
              removeLabel={labels.remove}
              isUploading={isUploading === 'logo'}
              onUpload={(file) => onUpload('logo', file)}
              onClear={() => onSetMediaUrl('logo', null)}
            />
            <MediaPicker
              testId="logo"
              mediaOptions={mediaOptions}
              onPick={(url) => onSetMediaUrl('logo', url)}
              label={labels.useExisting}
            />
            <MediaField
              testId="cover"
              title={labels.coverImage}
              value={draft.coverUrl}
              uploadLabel={labels.uploadCover}
              removeLabel={labels.remove}
              isUploading={isUploading === 'cover'}
              onUpload={(file) => onUpload('cover', file)}
              onClear={() => onSetMediaUrl('cover', null)}
            />
            <MediaPicker
              testId="cover"
              mediaOptions={mediaOptions}
              onPick={(url) => onSetMediaUrl('cover', url)}
              label={labels.useExisting}
            />
            <MediaField
              testId="background"
              title={labels.backgroundImage}
              value={draft.backgroundUrl}
              uploadLabel={labels.uploadBackground}
              removeLabel={labels.remove}
              isUploading={isUploading === 'background'}
              onUpload={(file) => onUpload('background', file)}
              onClear={() => onSetMediaUrl('background', null)}
            />
            <MediaPicker
              testId="background"
              mediaOptions={mediaOptions}
              onPick={(url) => onSetMediaUrl('background', url)}
              label={labels.useExisting}
            />
          </div>
        </div>
      </div>
    </section>
  );
}

function SettingGroup({
  label,
  children,
  className,
}: {
  label: string;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={className}>
      <p className="text-xs font-black uppercase tracking-[0.2em] text-muted">{label}</p>
      <div className="mt-3">{children}</div>
    </div>
  );
}

function OptionRow({ children }: { children: ReactNode }) {
  return <div className="flex flex-wrap gap-3">{children}</div>;
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
      className={`inline-flex h-11 min-h-11 min-w-11 items-center justify-center rounded-full border px-4 py-2.5 text-xs font-black uppercase tracking-[0.16em] transition ${
        active ? 'border-primary bg-primary text-white' : 'border-border bg-bg text-textStrong hover:border-primary/30'
      }`}
      style={{ height: 44, minHeight: 44, minWidth: 44 }}
    >
      {children}
    </button>
  );
}

function ToggleCard({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}) {
  return (
    <label className="flex min-h-11 items-center justify-between gap-3 rounded-[24px] border border-border bg-bg px-4 py-3 text-sm font-semibold text-textStrong">
      <span>{label}</span>
      <input
        type="checkbox"
        checked={checked}
        onChange={(event) => onChange(event.target.checked)}
        className="h-4 w-4 accent-primary"
      />
    </label>
  );
}

function MediaField({
  testId,
  title,
  value,
  uploadLabel,
  removeLabel,
  isUploading,
  onUpload,
  onClear,
}: {
  testId: string;
  title: string;
  value: string | null;
  uploadLabel: string;
  removeLabel: string;
  isUploading: boolean;
  onUpload: (file: File | null) => void;
  onClear: () => void;
}) {
  return (
    <div data-testid={`media-field-${testId}`} className="rounded-[24px] border border-border bg-bg p-4">
      <div className="flex items-center justify-between gap-3">
        <p className="text-sm font-black text-textStrong">{title}</p>
        {value ? (
          <button
            type="button"
            onClick={onClear}
            className="inline-flex h-11 min-h-11 min-w-11 items-center justify-center rounded-2xl px-3 py-2 text-xs font-black uppercase tracking-[0.16em] text-primary"
            style={{ height: 44, minHeight: 44, minWidth: 44 }}
          >
            {removeLabel}
          </button>
        ) : null}
      </div>
      {value ? (
        <div className="relative mt-3 h-28 overflow-hidden rounded-2xl">
          <img src={value} alt={title} loading="lazy" decoding="async" className="h-full w-full object-cover" />
        </div>
      ) : null}
      <label
        className="mt-3 inline-flex h-11 min-h-11 min-w-11 cursor-pointer items-center rounded-2xl border border-border bg-card px-4 py-3 text-sm font-black text-textStrong transition hover:border-primary/30"
        style={{ height: 44, minHeight: 44, minWidth: 44 }}
      >
        {isUploading ? `${uploadLabel}...` : uploadLabel}
        <input
          type="file"
          accept="image/jpeg,image/png,image/webp,image/gif,image/heic,image/heif"
          className="sr-only"
          onChange={(event) => onUpload(event.target.files?.[0] ?? null)}
        />
      </label>
    </div>
  );
}

function MediaPicker({
  testId,
  mediaOptions,
  onPick,
  label,
}: {
  testId: string;
  mediaOptions: MediaOption[];
  onPick: (url: string) => void;
  label: string;
}) {
  if (mediaOptions.length === 0) return null;

  return (
    <div data-testid={`media-picker-${testId}`} className="flex flex-wrap gap-3">
      {mediaOptions.map((option) => (
        <button
          key={option.id}
          type="button"
          onClick={() => onPick(option.url)}
          className="inline-flex h-11 min-h-11 min-w-11 items-center justify-center rounded-full border border-border bg-card px-3 py-2.5 text-xs font-black uppercase tracking-[0.14em] text-textStrong transition hover:border-primary/30"
          style={{ height: 44, minHeight: 44, minWidth: 44 }}
          title={option.url}
        >
          {label}: {option.label}
        </button>
      ))}
    </div>
  );
}
