export interface ApiKey {
  id: string;
  name: string;
  prefix: string;
  scope: string;
  created_by: string | null;
  created_at: string;
  updated_at: string;
  last_used_at: string | null;
  expires_at: string | null;
  is_active: boolean;
  created_by_name?: string | null;
}

export type AnahtarDurum = 'active' | 'expiring' | 'expired' | 'inactive';

const DAY = 86_400_000;

export function anahtarDurum(k: Pick<ApiKey, 'is_active' | 'expires_at'>, now = Date.now()): AnahtarDurum {
  if (!k.is_active) return 'inactive';
  if (k.expires_at) {
    const t = new Date(k.expires_at).getTime();
    if (t < now) return 'expired';
    if (t < now + 7 * DAY) return 'expiring';
  }
  return 'active';
}

export const DURUM_ETIKETLERI: Record<AnahtarDurum, string> = {
  active: 'Aktif',
  expiring: 'Süresi Yaklaşıyor',
  expired: 'Süresi Doldu',
  inactive: 'Pasif',
};

export const DURUM_RENKLERI: Record<AnahtarDurum, string> = {
  active: 'bg-emerald-50 text-emerald-700',
  expiring: 'bg-amber-50 text-amber-700',
  expired: 'bg-rose-50 text-rose-700',
  inactive: 'bg-zinc-100 text-zinc-600',
};

export const SCOPE_ETIKETLERI: Record<string, string> = {
  'read': 'Salt Okuma',
  'read:businesses': 'İşletme Okuma',
  'read:menus': 'Menü Okuma',
  'read_write': 'Okuma + Yazma',
  'read,write': 'Okuma + Yazma',
  'write': 'Yazma',
  'admin': 'Admin (Tam Erişim)',
  'menu:read': 'Menü Okuma (Yüksek Limit)',
};

export function scopeEtiket(scope: string): string {
  return SCOPE_ETIKETLERI[scope] ?? scope;
}

export function scopeRenk(scope: string): string {
  if (scope === 'admin') return 'bg-rose-50 text-rose-700';
  if (scope.includes('write')) return 'bg-amber-50 text-amber-700';
  return 'bg-blue-50 text-blue-700';
}

export function trend(current: number, previous: number): { value: number; label?: string } | undefined {
  if (previous === 0) return current === 0 ? undefined : { value: 100, label: 'önceki 7 gün: 0' };
  const pct = Math.round(((current - previous) / previous) * 100);
  return { value: pct, label: `önceki 7 gün: ${previous}` };
}

export function goreliZaman(iso: string | null): string {
  if (!iso) return 'Hiç kullanılmadı';
  const diffMs = Date.now() - new Date(iso).getTime();
  const diffMin = Math.floor(diffMs / 60_000);
  if (diffMin < 1) return 'az önce';
  if (diffMin < 60) return `${diffMin} dk önce`;
  const diffHour = Math.floor(diffMin / 60);
  if (diffHour < 24) return `${diffHour} sa önce`;
  const diffDay = Math.floor(diffHour / 24);
  if (diffDay < 30) return `${diffDay} gün önce`;
  return new Date(iso).toLocaleDateString('tr-TR');
}

export function anahtarCsvOlustur(rows: ApiKey[]): string {
  const header = ['Ad', 'Prefix', 'Kapsam', 'Durum', 'Oluşturan', 'Oluşturulma', 'Son Kullanım', 'Bitiş'];
  const lines = rows.map((k) => [
    k.name,
    k.prefix,
    scopeEtiket(k.scope),
    DURUM_ETIKETLERI[anahtarDurum(k)],
    k.created_by_name ?? '',
    new Date(k.created_at).toLocaleString('tr-TR'),
    k.last_used_at ? new Date(k.last_used_at).toLocaleString('tr-TR') : 'Hiç kullanılmadı',
    k.expires_at ? new Date(k.expires_at).toLocaleString('tr-TR') : 'Sınırsız',
  ].map((v) => `"${String(v).replace(/"/g, '""')}"`).join(','));
  return [header.join(','), ...lines].join('\n');
}
