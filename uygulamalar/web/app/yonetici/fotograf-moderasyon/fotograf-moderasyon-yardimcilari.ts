export interface ModerasyonFotografi {
  id: string;
  business_id: string;
  created_by: string | null;
  url: string;
  url_thumb: string | null;
  kind: string;
  status: string;
  is_hidden: boolean;
  created_at: string;
  business_name: string | null;
  business_category: string | null;
}

export const KIND_ETIKETLERI: Record<string, string> = {
  logo: 'Logo',
  cover: 'Kapak',
  hero: 'Kapak',
  gallery: 'Galeri',
};

export function kindEtiket(kind: string): string {
  return KIND_ETIKETLERI[kind] ?? kind;
}

export const STATUS_ETIKETLERI: Record<string, string> = {
  pending: 'Bekliyor',
  approved: 'Onaylandı',
  rejected: 'Reddedildi',
};

export const STATUS_RENKLERI: Record<string, string> = {
  pending: 'bg-amber-50 text-amber-700',
  approved: 'bg-emerald-50 text-emerald-700',
  rejected: 'bg-red-50 text-red-700',
};

export function trend(current: number, previous: number): { value: number; label?: string } | undefined {
  if (previous === 0) return current === 0 ? undefined : { value: 100, label: 'önceki 7 gün: 0' };
  const pct = Math.round(((current - previous) / previous) * 100);
  return { value: pct, label: `önceki 7 gün: ${previous}` };
}

export function fotografCsvOlustur(rows: ModerasyonFotografi[]): string {
  const header = ['ID', 'İşletme', 'Kategori', 'İçerik Türü', 'Durum', 'Gizli mi', 'Yükleme Tarihi'];
  const lines = rows.map((p) => [
    p.id,
    p.business_name ?? '',
    p.business_category ?? '',
    kindEtiket(p.kind),
    STATUS_ETIKETLERI[p.status] ?? p.status,
    p.is_hidden ? 'Evet' : 'Hayır',
    new Date(p.created_at).toLocaleString('tr-TR'),
  ].map((v) => `"${String(v).replace(/"/g, '""')}"`).join(','));
  return [header.join(','), ...lines].join('\n');
}
