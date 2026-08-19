export type YorumDurumu = 'pending' | 'approved' | 'rejected';

export const DURUM_ETIKETLERI: Record<YorumDurumu, string> = {
  pending: 'Beklemede',
  approved: 'Onaylanmış',
  rejected: 'Reddedilmiş',
};

export const DURUM_RENKLERI: Record<YorumDurumu, string> = {
  pending: 'bg-amber-50 text-amber-700',
  approved: 'bg-green-50 text-green-700',
  rejected: 'bg-red-50 text-red-700',
};

export interface YorumSatiri {
  id: string;
  title: string | null;
  content: string;
  rating: number;
  status: string;
  createdAt: string;
  businessId: string;
  businessName: string | null;
  businessSlug: string | null;
  businessCategory: string | null;
  userName: string | null;
  helpfulCount: number;
  hasOwnerReply: boolean;
  reportCount: number;
}

export function yorumlarCsvOlustur(rows: YorumSatiri[]): string {
  const basliklar = ['İşletme', 'Kullanıcı', 'Puan', 'Başlık', 'İçerik', 'Durum', 'Tarih'];
  const satirlar = rows.map((r) => [
    r.businessName ?? '',
    r.userName ?? '',
    String(r.rating),
    r.title ?? '',
    r.content,
    DURUM_ETIKETLERI[(r.status as YorumDurumu)] ?? r.status,
    new Date(r.createdAt).toLocaleDateString('tr-TR'),
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}

export function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}
