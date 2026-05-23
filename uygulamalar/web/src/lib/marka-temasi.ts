import {
  getTemplateDefinition,
  getTemplateOptions,
  resolveTemplateKey,
  type TemplateDefinition,
} from '@/src/lib/sablonlar/sablon-kaydi';
import type { TemplateKey } from '@/src/lib/sablonlar/sablon-calisma';

export type BrandTheme = TemplateKey;
export type BrandThemeDefinition = TemplateDefinition & {
  label: TemplateDefinition['displayName'];
};

export function resolveBrandTheme(input?: string | null): BrandTheme {
  return resolveTemplateKey(input);
}

export function getBrandThemeDefinition(theme: BrandTheme) {
  const template = getTemplateDefinition(theme);
  return {
    ...template,
    label: template.displayName,
  };
}

export function getBrandThemeOptions() {
  return getTemplateOptions().map((template) => ({
    id: template.key,
    label: template.displayName,
    description: template.description,
  }));
}
