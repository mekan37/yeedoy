export interface FiyatOneriSatiri {
  id: string;
  itemName: string;
  businessName: string | null;
  currentPriceCents: number | null;
  currentCurrency: string;
  suggestedPriceCents: number;
  suggestedCurrency: string;
  note: string | null;
  status: string;
  qualityConfidence: number | null;
  onsiteVerified: boolean;
  createdAt: string;
}

export type DurumAnahtari = 'pending' | 'approved' | 'rejected';

export const DURUM_ETIKETLERI: Record<DurumAnahtari, string> = {
  pending: 'Bekleyen',
  approved: 'Onaylanan',
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

export function fiyatFormatla(cents: number | null, currency: string): string {
  if (cents === null) return '—';
  return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: currency || 'TRY', minimumFractionDigits: 2 }).format(cents / 100);
}

export function fiyatOnerileriCsvOlustur(rows: FiyatOneriSatiri[]): string {
  const basliklar = ['Ürün', 'İşletme', 'Mevcut Fiyat', 'Önerilen Fiyat', 'Güven', 'Yerinde Doğrulandı', 'Not', 'Durum', 'Tarih'];
  const satirlar = rows.map((r) => [
    r.itemName,
    r.businessName ?? '',
    fiyatFormatla(r.currentPriceCents, r.currentCurrency),
    fiyatFormatla(r.suggestedPriceCents, r.suggestedCurrency),
    r.qualityConfidence != null ? `%${Math.round(r.qualityConfidence * 100)}` : '',
    r.onsiteVerified ? 'Evet' : 'Hayır',
    r.note ?? '',
    DURUM_ETIKETLERI[durumAnahtari(r.status)],
    new Date(r.createdAt).toLocaleDateString('tr-TR'),
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}
