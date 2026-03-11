import { z } from 'zod';
import type { Json } from '@/src/lib/supabase/database.types';
import {
  defaultLangSchema,
  presentationRecordSchema,
  presentationSettingsSchema,
  templateKeySchema,
} from '@/src/lib/templates/schema';
import {
  type DefaultLang,
  DEFAULT_PRESENTATION_SETTINGS,
  type PresentationRecord,
  type PresentationSettings,
  type TemplateKey,
} from '@/src/lib/templates/runtime';
import { resolveTemplateKey } from '@/src/lib/templates/registry';

const nullableUrlSchema = z
  .string()
  .trim()
  .url()
  .nullable()
  .optional()
  .transform((value) => value ?? null);

export const presentationSavePayloadSchema = z.object({
  businessId: z.string().uuid(),
  defaultLang: defaultLangSchema,
  templateKey: templateKeySchema,
  settings: presentationSettingsSchema,
  logoUrl: nullableUrlSchema,
  coverUrl: nullableUrlSchema,
  backgroundUrl: nullableUrlSchema,
});

export type PresentationSavePayload = z.infer<typeof presentationSavePayloadSchema>;

export type ResolvedPresentationRecord = PresentationRecord & {
  settings: PresentationSettings;
  templateKey: TemplateKey;
  defaultLang: DefaultLang;
};

export const DEFAULT_PRESENTATION_RECORD: ResolvedPresentationRecord = {
  businessId: '00000000-0000-0000-0000-000000000000',
  defaultLang: 'tr',
  templateKey: 'bold',
  settings: DEFAULT_PRESENTATION_SETTINGS,
  logoUrl: null,
  coverUrl: null,
  backgroundUrl: null,
  updatedAt: null,
};

export function parsePresentationSettingsJson(value: Json | null | undefined) {
  const parsed = presentationSettingsSchema.safeParse(value ?? {});
  return parsed.success ? parsed.data : DEFAULT_PRESENTATION_SETTINGS;
}

export function resolvePresentationRecord(input: {
  businessId: string;
  defaultLang?: string | null;
  templateKey?: string | null;
  settings?: Json | null;
  logoUrl?: string | null;
  coverUrl?: string | null;
  backgroundUrl?: string | null;
  updatedAt?: string | null;
} | null) {
  if (!input) return null;

  const candidate = {
    businessId: input.businessId,
    defaultLang: defaultLangSchema.safeParse(input.defaultLang).success ? input.defaultLang : 'tr',
    templateKey: resolveTemplateKey(input.templateKey),
    settings: parsePresentationSettingsJson(input.settings),
    logoUrl: normalizeNullableUrl(input.logoUrl),
    coverUrl: normalizeNullableUrl(input.coverUrl),
    backgroundUrl: normalizeNullableUrl(input.backgroundUrl),
    updatedAt: input.updatedAt ?? null,
  };

  const parsed = presentationRecordSchema.safeParse(candidate);
  return parsed.success ? (parsed.data as ResolvedPresentationRecord) : null;
}

export function normalizeNullableUrl(value?: string | null) {
  const trimmed = value?.trim();
  if (!trimmed) return null;
  return z.string().url().safeParse(trimmed).success ? trimmed : null;
}
