export const colors = {
  primary: '#7F1D1D',
  slate: '#434D57',
  bg: '#F9FAFB',
  card: '#FFFFFF',
  border: '#E5E7EB',
  text: '#434D57',
  muted: '#6B7280',
  success: '#15803D',
  warning: '#F59E0B',
  danger: '#B91C1C',
  info: '#1D4ED8',
  star: '#FBBF24',
  starOff: '#D1D5DB',
} as const;

export type AppColorToken = keyof typeof colors;

export function toRgbTriplet(hex: string): string {
  const value = hex.replace('#', '');
  const normalized =
    value.length === 3
      ? value
          .split('')
          .map((c) => `${c}${c}`)
          .join('')
      : value;

  const int = Number.parseInt(normalized, 16);
  const r = (int >> 16) & 255;
  const g = (int >> 8) & 255;
  const b = int & 255;
  return `${r} ${g} ${b}`;
}

export const colorRgbVars = Object.fromEntries(
  Object.entries(colors).map(([key, hex]) => [key, toRgbTriplet(hex)]),
) as Record<AppColorToken, string>;
