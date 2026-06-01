export interface BusinessLocation {
  lat: number;
  lng: number;
}

/**
 * Parse a PostGIS POINT string like "POINT(lng lat)" to a BusinessLocation.
 * Returns null if the string is not in expected format.
 * Note: Yeedoy currently stores lat/lng as separate double precision columns,
 * so this helper is provided for future-proofing only.
 */
export function parsePointToLatLng(point: string): BusinessLocation | null {
  const match = point.match(/POINT\(([^ ]+) ([^ )]+)\)/);
  if (!match) return null;
  return { lng: parseFloat(match[1]), lat: parseFloat(match[2]) };
}
