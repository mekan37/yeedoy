export interface OneriSatiri {
  id: string;
  name: string;
  category: string | null;
  city: string | null;
  district: string | null;
  note: string | null;
  status: string;
  createdAt: string;
  submitterName: string | null;
}

export type DurumAnahtari = 'pending' | 'approved' | 'rejected';

export const DURUM_ETIKETLERI: Record<DurumAnahtari, string> = {
  pending: 'Bekleyen',
  approved: 'Değerlendirilen',
  rejected: 'Reddedilen',
};

export const DURUM_RENKLERI: Record<DurumAnahtari, string> = {
  pending: 'bg-amber-50 text-amber-700',
  approved: 'bg-green-50 text-green-700',
  rejected: 'bg-red-50 text-red-700',
};

export function durumAnahtari(status: string): DurumAnahtari {
  if (status === 'approved') return 'approved';
  if (status === 'rejected') return 'rejected';
  return 'pending';
}

export function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}

export function onerilerCsvOlustur(rows: OneriSatiri[]): string {
  const basliklar = ['Öneri', 'Kategori', 'Şehir', 'İlçe', 'Not', 'Kullanıcı', 'Durum', 'Tarih'];
  const satirlar = rows.map((r) => [
    r.name,
    r.category ?? '',
    r.city ?? '',
    r.district ?? '',
    r.note ?? '',
    r.submitterName ?? '',
    DURUM_ETIKETLERI[durumAnahtari(r.status)],
    new Date(r.createdAt).toLocaleDateString('tr-TR'),
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}
