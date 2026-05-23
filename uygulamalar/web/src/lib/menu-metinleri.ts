import type { PublicMenuData } from '@/src/lib/veri/menu-okuma';

export function getTranslationValue(input: {
  translations: PublicMenuData['translations'];
  entityType: 'business' | 'category' | 'item';
  entityId: string;
  locale: string;
  field: 'name' | 'description';
  fallback?: string | null;
}) {
  const exact = input.translations.find(
    (entry) =>
      entry.entity_type === input.entityType &&
      entry.entity_id === input.entityId &&
      entry.locale === input.locale,
  );
  if (exact?.[input.field]) return exact[input.field];

  const language = input.locale.split('-')[0];
  const partial = input.translations.find(
    (entry) =>
      entry.entity_type === input.entityType &&
      entry.entity_id === input.entityId &&
      entry.locale.toLowerCase().startsWith(language.toLowerCase()),
  );

  return partial?.[input.field] ?? input.fallback ?? null;
}
