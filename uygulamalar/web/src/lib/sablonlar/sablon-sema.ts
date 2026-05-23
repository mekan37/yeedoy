import { z } from 'zod';
import {
  ACCENT_PRESETS,
  BACKGROUND_MODES,
  CARD_STYLES,
  DEFAULT_LANGS,
  DEFAULT_PRESENTATION_SETTINGS,
  FONT_SCALES,
  HEADER_LAYOUTS,
  LAYOUT_VARIANTS,
  TEMPLATE_KEYS,
  type DefaultLang,
  type PresentationRecord,
  type PresentationSettings,
  type TemplateKey,
} from '@/src/lib/sablonlar/sablon-calisma';

export const templateKeySchema = z.enum(TEMPLATE_KEYS);

export const defaultLangSchema = z.enum(DEFAULT_LANGS);

export const backgroundModeSchema = z.enum(BACKGROUND_MODES);
export const accentPresetSchema = z.enum(ACCENT_PRESETS);
export const headerLayoutSchema = z.enum(HEADER_LAYOUTS);
export const cardStyleSchema = z.enum(CARD_STYLES);
export const fontScaleSchema = z.enum(FONT_SCALES);
export const layoutVariantSchema = z.enum(LAYOUT_VARIANTS);

export const presentationSettingsSchema = z.object({
  backgroundMode: backgroundModeSchema.default('gradient'),
  accentPreset: accentPresetSchema.default('brand'),
  accentHex: z
    .string()
    .trim()
    .regex(/^#(?:[0-9a-fA-F]{3}){1,2}$/)
    .nullable()
    .optional(),
  headerLayout: headerLayoutSchema.default('left'),
  cardStyle: cardStyleSchema.default('comfortable'),
  showFeatured: z.boolean().default(true),
  showTags: z.boolean().default(true),
  showAllergens: z.boolean().default(true),
  showCurrencySymbol: z.boolean().default(true),
  showLastUpdated: z.boolean().default(true),
  fontScale: fontScaleSchema.default('normal'),
  layoutVariant: layoutVariantSchema.default('standard'),
});

export const presentationRecordSchema = z.object({
  businessId: z.string().uuid(),
  defaultLang: defaultLangSchema.default('tr'),
  templateKey: templateKeySchema.default('bold'),
  settings: presentationSettingsSchema,
  logoUrl: z.string().trim().url().nullable().optional(),
  coverUrl: z.string().trim().url().nullable().optional(),
  backgroundUrl: z.string().trim().url().nullable().optional(),
  updatedAt: z.string().nullable().optional(),
});

type SchemaTemplateKey = z.infer<typeof templateKeySchema>;
type SchemaDefaultLang = z.infer<typeof defaultLangSchema>;
type SchemaPresentationSettings = z.infer<typeof presentationSettingsSchema>;
type SchemaPresentationRecord = z.infer<typeof presentationRecordSchema>;

const _templateKeyTypeCheck: TemplateKey = null as unknown as SchemaTemplateKey;
const _defaultLangTypeCheck: DefaultLang = null as unknown as SchemaDefaultLang;
const _presentationSettingsTypeCheck: PresentationSettings = null as unknown as SchemaPresentationSettings;
const _presentationRecordTypeCheck: PresentationRecord = null as unknown as SchemaPresentationRecord;

void _templateKeyTypeCheck;
void _defaultLangTypeCheck;
void _presentationSettingsTypeCheck;
void _presentationRecordTypeCheck;
