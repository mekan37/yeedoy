import type { PresentationSettings, TemplateKey } from '@/src/lib/templates/runtime';

const templateAccentFallback: Record<TemplateKey, string> = {
  minimal: '#111827',
  bold: '#7f1d1d',
  elegant: '#5c1515',
  'photo-heavy': '#312e81',
  'dark-modern': '#22d3ee',
};

export function resolveAccentColor(input: {
  templateKey: TemplateKey;
  settings: PresentationSettings;
}) {
  if (input.settings.accentPreset === 'custom' && input.settings.accentHex) {
    return input.settings.accentHex;
  }

  switch (input.settings.accentPreset) {
    case 'slate':
      return '#111827';
    case 'forest':
      return '#14532d';
    case 'amber':
      return '#b45309';
    case 'rose':
      return '#be123c';
    case 'custom':
    case 'brand':
    default:
      return templateAccentFallback[input.templateKey];
  }
}
