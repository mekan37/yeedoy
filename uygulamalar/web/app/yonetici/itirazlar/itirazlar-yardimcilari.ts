export type ItirazDurumu = 'pending' | 'reviewing' | 'approved' | 'rejected';

export const DURUM_ETIKETLERI: Record<ItirazDurumu, string> = {
  pending: 'Beklemede',
  reviewing: 'İnceleniyor',
  approved: 'Onaylandı',
  rejected: 'Reddedildi',
};

export const DURUM_RENKLERI: Record<ItirazDurumu, string> = {
  pending: 'bg-amber-50 text-amber-700',
  reviewing: 'bg-blue-50 text-blue-700',
  approved: 'bg-green-50 text-green-700',
  rejected: 'bg-red-50 text-red-700',
};

export type KaynakTuru = 'review' | 'business' | 'menu_item' | 'user';

export const KAYNAK_ETIKETLERI: Record<KaynakTuru, string> = {
  review: 'Yorum',
  business: 'İşletme',
  menu_item: 'Menü Öğesi',
  user: 'Kullanıcı',
};

export interface ItirazSatiri {
  id: string;
  sourceType: string;
  sourceId: string;
  reason: string;
  details: string | null;
  status: string;
  createdAt: string;
  decidedAt: string | null;
  appellantName: string | null;
  appellantEmail: string | null;
  contentLabel: string | null;
  assignedToName: string | null;
}

export function itirazDurumu(row: { status: string; assignedToName: string | null }): ItirazDurumu {
  if (row.status === 'approved') return 'approved';
  if (row.status === 'rejected') return 'rejected';
  if (row.assignedToName) return 'reviewing';
  return 'pending';
}

export function itirazNoOlustur(id: string, createdAt: string): string {
  const yil = new Date(createdAt).getFullYear();
  return `#AP-${yil}-${id.replace(/-/g, '').slice(0, 4).toUpperCase()}`;
}

export function itirazlarCsvOlustur(rows: ItirazSatiri[]): string {
  const basliklar = ['İtiraz No', 'İtiraz Sahibi', 'İlgili Tür', 'İlgili İçerik', 'Neden', 'Durum', 'Tarih'];
  const satirlar = rows.map((r) => [
    itirazNoOlustur(r.id, r.createdAt),
    r.appellantName ?? '',
    KAYNAK_ETIKETLERI[(r.sourceType as KaynakTuru)] ?? r.sourceType,
    r.contentLabel ?? '',
    r.reason,
    DURUM_ETIKETLERI[itirazDurumu(r)],
    new Date(r.createdAt).toLocaleDateString('tr-TR'),
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}

export function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}
