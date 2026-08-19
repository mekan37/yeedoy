export interface BasvuruSatiri {
  id: string;
  name: string;
  category: string;
  city: string;
  district: string;
  status: string;
  createdAt: string;
  submittedByName: string | null;
  assignedToName: string | null;
}

export function basvuruNoOlustur(id: string): string {
  return `#TB-${id.replace(/-/g, '').slice(0, 5).toUpperCase()}`;
}

export function basvurularCsvOlustur(rows: BasvuruSatiri[]): string {
  const basliklar = ['Başvuru No', 'İşletme', 'Kategori', 'Şehir', 'İlçe', 'Başvuran', 'Durum', 'Başvuru Tarihi'];
  const satirlar = rows.map((r) => [
    basvuruNoOlustur(r.id),
    r.name,
    r.category,
    r.city,
    r.district,
    r.submittedByName ?? '',
    DURUM_ETIKETLERI[durumAnahtari(r)] ?? r.status,
    new Date(r.createdAt).toLocaleDateString('tr-TR'),
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}

export type DurumAnahtari = 'pending' | 'reviewing' | 'approved' | 'rejected';

export function durumAnahtari(row: { status: string; assignedToName: string | null }): DurumAnahtari {
  if (row.status === 'approved') return 'approved';
  if (row.status === 'rejected') return 'rejected';
  if (row.assignedToName) return 'reviewing';
  return 'pending';
}

export const DURUM_ETIKETLERI: Record<DurumAnahtari, string> = {
  pending: 'Beklemede',
  reviewing: 'İncelemede',
  approved: 'Onaylandı',
  rejected: 'Reddedildi',
};

export const DURUM_RENKLERI: Record<DurumAnahtari, string> = {
  pending: 'bg-amber-50 text-amber-700',
  reviewing: 'bg-violet-50 text-violet-700',
  approved: 'bg-green-50 text-green-700',
  rejected: 'bg-red-50 text-red-700',
};

export function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}
