function normalizeUuid(uuid: string) {
  const normalized = uuid.trim().toLowerCase();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(normalized)) {
    throw new Error('Invalid UUID');
  }
  return normalized;
}

function bytesToBase64Url(bytes: Uint8Array) {
  if (typeof Buffer !== 'undefined') {
    return Buffer.from(bytes).toString('base64url');
  }

  let binary = '';
  bytes.forEach((value) => {
    binary += String.fromCharCode(value);
  });

  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/u, '');
}

function base64UrlToBytes(value: string) {
  const base64 = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, '=');

  if (typeof Buffer !== 'undefined') {
    return new Uint8Array(Buffer.from(padded, 'base64'));
  }

  const binary = atob(padded);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

export function encodeBusinessCode(uuid: string) {
  const normalized = normalizeUuid(uuid).replace(/-/g, '');
  const bytes = Uint8Array.from(normalized.match(/.{1,2}/gu) ?? [], (pair) => parseInt(pair, 16));
  return bytesToBase64Url(bytes);
}

export function decodeBusinessCode(code: string) {
  try {
    const bytes = base64UrlToBytes(code.trim());
    if (bytes.length !== 16) return null;
    const hex = Array.from(bytes, (value) => value.toString(16).padStart(2, '0')).join('');
    const uuid = [
      hex.slice(0, 8),
      hex.slice(8, 12),
      hex.slice(12, 16),
      hex.slice(16, 20),
      hex.slice(20, 32),
    ].join('-');
    return normalizeUuid(uuid);
  } catch {
    return null;
  }
}
