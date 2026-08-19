export interface SilinmisMenuSatiri {
  id: string;
  title: string;
  businessId: string;
  businessName: string | null;
  businessCity: string | null;
  businessDistrict: string | null;
  businessCategory: string | null;
  ownerName: string | null;
  updatedAt: string;
  activeTo: string | null;
}

export function menuNoOlustur(id: string): string {
  return `#M-${id.replace(/-/g, '').slice(0, 6).toUpperCase()}`;
}

export function silinmisMenulerCsvOlustur(rows: SilinmisMenuSatiri[]): string {
  const basliklar = ['Menü Adı', 'Menü No', 'İşletme', 'Şehir', 'Menü Sahibi', 'Arşivlenme Tarihi', 'Süre Bitişi'];
  const satirlar = rows.map((r) => [
    r.title,
    menuNoOlustur(r.id),
    r.businessName ?? '',
    [r.businessDistrict, r.businessCity].filter(Boolean).join(', '),
    r.ownerName ?? '',
    new Date(r.updatedAt).toLocaleDateString('tr-TR'),
    r.activeTo ? new Date(r.activeTo).toLocaleDateString('tr-TR') : '',
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}
