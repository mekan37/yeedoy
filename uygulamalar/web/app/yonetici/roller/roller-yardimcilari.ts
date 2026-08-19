import type { AdminPermissionKey } from '@/src/lib/admin-izinler';

export interface AdminRole {
  id: string;
  name: string;
  description: string | null;
  is_system: boolean;
  is_active: boolean;
  permissions: AdminPermissionKey[];
  created_at: string;
  updated_at: string;
  updated_by: string | null;
  updated_by_name?: string | null;
  userCount: number;
}

export function trend(current: number, previous: number): { value: number; label?: string } | undefined {
  if (previous === 0) return current === 0 ? undefined : { value: 100, label: 'önceki 7 gün: 0' };
  const pct = Math.round(((current - previous) / previous) * 100);
  return { value: pct, label: `önceki 7 gün: ${previous}` };
}

export function goreliZaman(iso: string): string {
  const diffMs = Date.now() - new Date(iso).getTime();
  const diffDay = Math.floor(diffMs / 86_400_000);
  if (diffDay < 1) return 'bugün';
  if (diffDay === 1) return '1 gün önce';
  if (diffDay < 7) return `${diffDay} gün önce`;
  const diffWeek = Math.floor(diffDay / 7);
  if (diffWeek < 5) return `${diffWeek} hafta önce`;
  return new Date(iso).toLocaleDateString('tr-TR');
}

export function rolCsvOlustur(rows: AdminRole[]): string {
  const header = ['Rol Adı', 'Açıklama', 'Tür', 'Kullanıcı Sayısı', 'Durum', 'Son Güncelleme', 'Güncelleyen'];
  const lines = rows.map((r) => [
    r.name,
    r.description ?? '',
    r.is_system ? 'Sistem' : 'Özel',
    String(r.userCount),
    r.is_active ? 'Aktif' : 'Pasif',
    new Date(r.updated_at).toLocaleString('tr-TR'),
    r.updated_by_name ?? '',
  ].map((v) => `"${String(v).replace(/"/g, '""')}"`).join(','));
  return [header.join(','), ...lines].join('\n');
}
