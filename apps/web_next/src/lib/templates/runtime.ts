export const TEMPLATE_KEYS = [
  'minimal',
  'bold',
  'elegant',
  'photo-heavy',
  'dark-modern',
] as const;

export const DEFAULT_LANGS = ['tr', 'en'] as const;
export const BACKGROUND_MODES = ['solid', 'gradient', 'image'] as const;
export const ACCENT_PRESETS = ['brand', 'slate', 'forest', 'amber', 'rose', 'custom'] as const;
export const HEADER_LAYOUTS = ['left', 'centered'] as const;
export const CARD_STYLES = ['compact', 'comfortable'] as const;
export const FONT_SCALES = ['normal', 'large'] as const;
export const LAYOUT_VARIANTS = ['standard', 'editorial', 'immersive'] as const;

export type TemplateKey = (typeof TEMPLATE_KEYS)[number];
export type DefaultLang = (typeof DEFAULT_LANGS)[number];
export type BackgroundMode = (typeof BACKGROUND_MODES)[number];
export type AccentPreset = (typeof ACCENT_PRESETS)[number];
export type HeaderLayout = (typeof HEADER_LAYOUTS)[number];
export type CardStyle = (typeof CARD_STYLES)[number];
export type FontScale = (typeof FONT_SCALES)[number];
export type LayoutVariant = (typeof LAYOUT_VARIANTS)[number];

export type PresentationSettings = {
  backgroundMode: BackgroundMode;
  accentPreset: AccentPreset;
  accentHex?: string | null;
  headerLayout: HeaderLayout;
  cardStyle: CardStyle;
  showFeatured: boolean;
  showTags: boolean;
  showAllergens: boolean;
  showCurrencySymbol: boolean;
  showLastUpdated: boolean;
  fontScale: FontScale;
  layoutVariant: LayoutVariant;
};

export type PresentationRecord = {
  businessId: string;
  defaultLang: DefaultLang;
  templateKey: TemplateKey;
  settings: PresentationSettings;
  logoUrl?: string | null;
  coverUrl?: string | null;
  backgroundUrl?: string | null;
  updatedAt?: string | null;
};

export const DEFAULT_PRESENTATION_SETTINGS: PresentationSettings = {
  backgroundMode: 'gradient',
  accentPreset: 'brand',
  accentHex: null,
  headerLayout: 'left',
  cardStyle: 'comfortable',
  showFeatured: true,
  showTags: true,
  showAllergens: true,
  showCurrencySymbol: true,
  showLastUpdated: true,
  fontScale: 'normal',
  layoutVariant: 'standard',
};
