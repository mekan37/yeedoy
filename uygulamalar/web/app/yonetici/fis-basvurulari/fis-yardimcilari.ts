import type { FisGonderim } from '@/src/lib/veri/admin/fis-gonderimleri-types';

export function fisNoOlustur(receiptId: string, createdAt: string): string {
  const yil = new Date(createdAt).getFullYear();
  return `#FIS-${yil}-${receiptId.replace(/-/g, '').slice(0, 4).toUpperCase()}`;
}

export function fisCsvOlustur(rows: FisGonderim[]): string {
  const basliklar = ['Fiş No', 'İşletme', 'Şehir', 'Zincir', 'Kullanıcı', 'Eşleşme', 'Durum', 'Tarih'];
  const satirlar = rows.map((r) => [
    fisNoOlustur(r.receipt_id, r.created_at),
    r.business_name ?? '',
    [r.district, r.city].filter(Boolean).join(', '),
    r.chain_name ?? '',
    r.submitter_display,
    `${r.matches_count} ürün`,
    r.review_status,
    new Date(r.created_at).toLocaleDateString('tr-TR'),
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}
