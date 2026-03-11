const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const businessSlugPattern = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export function isUuid(value: string) {
  return uuidPattern.test(value.trim());
}

export function normalizeBusinessMenuPathKey(value?: string | null) {
  const normalized = value?.trim().toLowerCase();
  return normalized ? normalized : null;
}

export function isBusinessMenuPathKey(value: string) {
  const normalized = normalizeBusinessMenuPathKey(value);
  return normalized !== null && (isUuid(normalized) || businessSlugPattern.test(normalized));
}
