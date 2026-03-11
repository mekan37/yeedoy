export function appendMediaVersion(url: string | null | undefined, version: string | null | undefined) {
  const normalizedUrl = url?.trim();
  const normalizedVersion = version?.trim();

  if (!normalizedUrl || !normalizedVersion) {
    return normalizedUrl ?? null;
  }

  try {
    const resolved = new URL(normalizedUrl);
    resolved.searchParams.set('v', normalizedVersion);
    return resolved.toString();
  } catch {
    return normalizedUrl;
  }
}
