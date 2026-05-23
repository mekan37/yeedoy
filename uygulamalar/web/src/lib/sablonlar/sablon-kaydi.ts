import type { ReactNode } from 'react';
import {
  DEFAULT_PRESENTATION_SETTINGS,
  type DefaultLang,
  type PresentationSettings,
  type TemplateKey,
} from '@/src/lib/sablonlar/sablon-calisma';
import { templateKeySchema } from '@/src/lib/sablonlar/sablon-sema';

type LocalizedLabel = {
  tr: string;
  en: string;
};

export type TemplateRenderer = 'default' | 'photo-heavy' | 'dark-modern';

export type TemplateDefinition = {
  key: TemplateKey;
  displayName: LocalizedLabel;
  description: LocalizedLabel;
  renderer: TemplateRenderer;
  supportedOptions: Array<keyof PresentationSettings>;
  defaultSettings: PresentationSettings;
  heroBackground: string;
  heroOrnament: string;
  featuredBackground: string;
  featuredAccent: string;
  qrPanelBackground: string;
  pageBackground: string;
  previewSurface: string;
  itemImageFallback: string;
  itemPriceClassName: string;
  itemCardClassName: string;
  placeholderBase: string;
  placeholderHighlight: string;
  brandQrDark: string;
};

const sharedOptions: Array<keyof PresentationSettings> = [
  'backgroundMode',
  'accentPreset',
  'accentHex',
  'headerLayout',
  'cardStyle',
  'showFeatured',
  'showTags',
  'showAllergens',
  'showCurrencySymbol',
  'showLastUpdated',
  'fontScale',
  'layoutVariant',
];

export const templateRegistry: Record<TemplateKey, TemplateDefinition> = {
  minimal: {
    key: 'minimal',
    displayName: { tr: 'Minimal', en: 'Minimal' },
    description: {
      tr: 'Sakin, rafine ve metin odakli sunum.',
      en: 'Calm, refined and text-led presentation.',
    },
    renderer: 'default',
    supportedOptions: sharedOptions,
    defaultSettings: {
      ...DEFAULT_PRESENTATION_SETTINGS,
      backgroundMode: 'solid',
      headerLayout: 'left',
      layoutVariant: 'standard',
    },
    heroBackground:
      'radial-gradient(circle at top left, rgba(255,255,255,0.2), transparent 40%), linear-gradient(135deg, rgba(17,24,39,0.96), rgba(67,77,87,0.92))',
    heroOrnament:
      'linear-gradient(135deg, rgba(255,255,255,0.15), rgba(255,255,255,0.02))',
    featuredBackground:
      'linear-gradient(180deg, rgba(255,255,255,0.98), rgba(249,250,251,0.94))',
    featuredAccent:
      'linear-gradient(135deg, rgba(17,24,39,0.08), rgba(67,77,87,0.02))',
    qrPanelBackground:
      'radial-gradient(circle at top, rgba(17,24,39,0.08), transparent 60%), linear-gradient(180deg, rgba(255,255,255,0.98), rgba(249,250,251,0.92))',
    pageBackground:
      'linear-gradient(180deg, rgba(248,248,248,1), rgba(255,255,255,1))',
    previewSurface:
      'linear-gradient(180deg, rgba(255,255,255,1), rgba(245,247,249,0.94))',
    itemImageFallback:
      'linear-gradient(135deg, rgba(17,24,39,0.08), rgba(67,77,87,0.02))',
    itemPriceClassName: 'border border-border bg-card text-textStrong',
    itemCardClassName:
      'border-border bg-card hover:-translate-y-1 hover:border-textStrong/15 hover:shadow-yd2 active:scale-[0.995]',
    placeholderBase: '#e5e7eb',
    placeholderHighlight: '#f9fafb',
    brandQrDark: '#111827',
  },
  bold: {
    key: 'bold',
    displayName: { tr: 'Bold', en: 'Bold' },
    description: {
      tr: 'Canli renkler ve iddiali vitrin.',
      en: 'High-contrast and energetic storefront.',
    },
    renderer: 'default',
    supportedOptions: sharedOptions,
    defaultSettings: {
      ...DEFAULT_PRESENTATION_SETTINGS,
      backgroundMode: 'gradient',
      headerLayout: 'left',
      layoutVariant: 'editorial',
    },
    heroBackground:
      'radial-gradient(circle at top left, rgba(255,255,255,0.34), transparent 42%), linear-gradient(135deg, rgba(127,29,29,1), rgba(220,38,38,1))',
    heroOrnament:
      'linear-gradient(135deg, rgba(255,255,255,0.24), rgba(255,255,255,0.04))',
    featuredBackground:
      'radial-gradient(circle at top right, rgba(127,29,29,0.08), transparent 38%), linear-gradient(180deg, rgba(255,255,255,1), rgba(253,248,247,0.94))',
    featuredAccent:
      'linear-gradient(135deg, rgba(127,29,29,0.12), rgba(220,38,38,0.03))',
    qrPanelBackground:
      'radial-gradient(circle at top, rgba(127,29,29,0.1), transparent 60%), linear-gradient(180deg, rgba(255,255,255,0.98), rgba(253,248,247,0.92))',
    pageBackground:
      'linear-gradient(180deg, rgba(254,250,249,1), rgba(255,255,255,1))',
    previewSurface:
      'linear-gradient(180deg, rgba(255,255,255,1), rgba(253,246,244,0.96))',
    itemImageFallback:
      'linear-gradient(135deg, rgba(127,29,29,0.08), rgba(220,38,38,0.02))',
    itemPriceClassName: 'bg-primary text-white shadow-yd1',
    itemCardClassName:
      'border-border bg-card hover:-translate-y-1 hover:border-primary/20 hover:shadow-yd2 active:scale-[0.995]',
    placeholderBase: '#f9e7e7',
    placeholderHighlight: '#fff5f5',
    brandQrDark: '#7f1d1d',
  },
  elegant: {
    key: 'elegant',
    displayName: { tr: 'Elegant', en: 'Elegant' },
    description: {
      tr: 'Premium servis hissi veren yumusak kontrast.',
      en: 'Soft premium contrast with fine-dining tone.',
    },
    renderer: 'default',
    supportedOptions: sharedOptions,
    defaultSettings: {
      ...DEFAULT_PRESENTATION_SETTINGS,
      backgroundMode: 'gradient',
      headerLayout: 'centered',
      layoutVariant: 'editorial',
    },
    heroBackground:
      'radial-gradient(circle at top left, rgba(255,248,240,0.26), transparent 40%), linear-gradient(135deg, rgba(92,21,21,1), rgba(67,77,87,0.92))',
    heroOrnament:
      'linear-gradient(135deg, rgba(255,248,240,0.2), rgba(255,255,255,0.03))',
    featuredBackground:
      'radial-gradient(circle at top right, rgba(92,21,21,0.08), transparent 38%), linear-gradient(180deg, rgba(255,252,248,1), rgba(250,245,240,0.94))',
    featuredAccent:
      'linear-gradient(135deg, rgba(92,21,21,0.12), rgba(107,114,128,0.03))',
    qrPanelBackground:
      'radial-gradient(circle at top, rgba(92,21,21,0.1), transparent 60%), linear-gradient(180deg, rgba(255,252,248,0.98), rgba(250,245,240,0.92))',
    pageBackground:
      'linear-gradient(180deg, rgba(255,252,248,1), rgba(250,245,240,0.96))',
    previewSurface:
      'linear-gradient(180deg, rgba(255,255,255,1), rgba(251,245,239,0.95))',
    itemImageFallback:
      'linear-gradient(135deg, rgba(92,21,21,0.08), rgba(107,114,128,0.02))',
    itemPriceClassName: 'bg-textStrong text-white shadow-yd1',
    itemCardClassName:
      'border-border bg-card hover:-translate-y-1 hover:border-primary/15 hover:shadow-yd2 active:scale-[0.995]',
    placeholderBase: '#efe6df',
    placeholderHighlight: '#fffaf5',
    brandQrDark: '#5c1515',
  },
  'photo-heavy': {
    key: 'photo-heavy',
    displayName: { tr: 'Photo Heavy', en: 'Photo Heavy' },
    description: {
      tr: 'Yemek fotografini merkeze alan daha istah acici vitrin.',
      en: 'Photo-led layout for image-rich menus.',
    },
    renderer: 'photo-heavy',
    supportedOptions: sharedOptions,
    defaultSettings: {
      ...DEFAULT_PRESENTATION_SETTINGS,
      backgroundMode: 'image',
      headerLayout: 'centered',
      layoutVariant: 'immersive',
      cardStyle: 'comfortable',
      showFeatured: true,
    },
    heroBackground:
      'radial-gradient(circle at top left, rgba(255,255,255,0.12), transparent 35%), linear-gradient(135deg, rgba(76,29,149,0.82), rgba(15,23,42,0.86))',
    heroOrnament:
      'linear-gradient(135deg, rgba(255,255,255,0.22), rgba(255,255,255,0.03))',
    featuredBackground:
      'linear-gradient(180deg, rgba(15,23,42,0.08), rgba(255,255,255,0.96))',
    featuredAccent:
      'linear-gradient(135deg, rgba(59,130,246,0.14), rgba(236,72,153,0.04))',
    qrPanelBackground:
      'radial-gradient(circle at top, rgba(59,130,246,0.12), transparent 60%), linear-gradient(180deg, rgba(255,255,255,0.98), rgba(244,247,255,0.92))',
    pageBackground:
      'linear-gradient(180deg, rgba(244,247,255,1), rgba(255,255,255,1))',
    previewSurface:
      'linear-gradient(180deg, rgba(255,255,255,1), rgba(241,245,255,0.95))',
    itemImageFallback:
      'linear-gradient(135deg, rgba(59,130,246,0.12), rgba(236,72,153,0.04))',
    itemPriceClassName: 'bg-slate-950 text-white shadow-yd1',
    itemCardClassName:
      'border-border bg-card hover:-translate-y-1 hover:border-slate-900/15 hover:shadow-yd2 active:scale-[0.995]',
    placeholderBase: '#e0e7ff',
    placeholderHighlight: '#f8fafc',
    brandQrDark: '#312e81',
  },
  'dark-modern': {
    key: 'dark-modern',
    displayName: { tr: 'Dark Modern', en: 'Dark Modern' },
    description: {
      tr: 'Gece servisi ve kokteyl menuleri icin koyu vitrin.',
      en: 'Dark editorial look for late-night concepts.',
    },
    renderer: 'dark-modern',
    supportedOptions: sharedOptions,
    defaultSettings: {
      ...DEFAULT_PRESENTATION_SETTINGS,
      backgroundMode: 'solid',
      headerLayout: 'left',
      layoutVariant: 'immersive',
      showFeatured: true,
      showTags: true,
    },
    heroBackground:
      'radial-gradient(circle at top left, rgba(15,23,42,0.24), transparent 38%), linear-gradient(135deg, rgba(2,6,23,1), rgba(15,23,42,0.96))',
    heroOrnament:
      'linear-gradient(135deg, rgba(56,189,248,0.22), rgba(255,255,255,0.02))',
    featuredBackground:
      'linear-gradient(180deg, rgba(15,23,42,1), rgba(30,41,59,0.98))',
    featuredAccent:
      'linear-gradient(135deg, rgba(34,211,238,0.16), rgba(59,130,246,0.04))',
    qrPanelBackground:
      'radial-gradient(circle at top, rgba(34,211,238,0.14), transparent 60%), linear-gradient(180deg, rgba(15,23,42,1), rgba(30,41,59,0.96))',
    pageBackground:
      'linear-gradient(180deg, rgba(2,6,23,1), rgba(15,23,42,1))',
    previewSurface:
      'linear-gradient(180deg, rgba(15,23,42,1), rgba(30,41,59,0.96))',
    itemImageFallback:
      'linear-gradient(135deg, rgba(34,211,238,0.12), rgba(15,23,42,0.3))',
    itemPriceClassName: 'bg-cyan-400 text-slate-950 shadow-yd1',
    itemCardClassName:
      'border-slate-700 bg-slate-900 text-white hover:-translate-y-1 hover:border-cyan-400/45 hover:shadow-yd2 active:scale-[0.995]',
    placeholderBase: '#0f172a',
    placeholderHighlight: '#1e293b',
    brandQrDark: '#22d3ee',
  },
};

export function resolveTemplateKey(input?: string | null): TemplateKey {
  const parsed = templateKeySchema.safeParse(input);
  return parsed.success ? parsed.data : 'bold';
}

export function getTemplateDefinition(key: TemplateKey) {
  return templateRegistry[key];
}

export function getTemplateOptions() {
  return Object.values(templateRegistry);
}

export function getTemplateLabel(key: TemplateKey, lang: DefaultLang) {
  return templateRegistry[key].displayName[lang];
}

export function noopRenderer(children: ReactNode) {
  return children;
}
