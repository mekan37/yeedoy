import { csvHucre } from '@/src/lib/csv-guvenli';

export interface IlSatiri {
  name: string;
  businessCount: number;
  activeCount: number;
  verifiedCount: number;
  districtCount: number;
}

export interface IlceSatiri {
  city: string;
  district: string;
  businessCount: number;
  activeCount: number;
  verifiedCount: number;
}

export function aktiflikOrani(businessCount: number, activeCount: number): number {
  return businessCount > 0 ? Math.round((activeCount / businessCount) * 100) : 0;
}

export function ilCsvOlustur(rows: IlSatiri[]): string {
  const basliklar = ['İl', 'Toplam İşletme', 'Aktif', 'Pasif', 'Doğrulanmış', 'Aktiflik Oranı', 'İlçe Sayısı'];
  const satirlar = rows.map((r) => [
    r.name,
    String(r.businessCount),
    String(r.activeCount),
    String(r.businessCount - r.activeCount),
    String(r.verifiedCount),
    `%${aktiflikOrani(r.businessCount, r.activeCount)}`,
    String(r.districtCount),
  ]);
  return [basliklar, ...satirlar].map((satir) => satir.map(csvHucre).join(',')).join('\n');
}

export function ilceCsvOlustur(rows: IlceSatiri[]): string {
  const basliklar = ['İlçe', 'İl', 'Toplam İşletme', 'Aktif', 'Pasif', 'Doğrulanmış', 'Aktiflik Oranı'];
  const satirlar = rows.map((r) => [
    r.district,
    r.city,
    String(r.businessCount),
    String(r.activeCount),
    String(r.businessCount - r.activeCount),
    String(r.verifiedCount),
    `%${aktiflikOrani(r.businessCount, r.activeCount)}`,
  ]);
  return [basliklar, ...satirlar].map((satir) => satir.map(csvHucre).join(',')).join('\n');
}
