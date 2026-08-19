export interface FraudRaporu {
  id: string;
  target_type: string;
  target_id: string;
  reason: string | null;
  details: string | null;
  status: string;
  created_at: string;
  admin_note: string | null;
}

export interface SuphelKullanici {
  user_id: string;
  review_count: number;
  display_name: string | null;
}

export function trend(current: number, previous: number): { value: number; label?: string } | undefined {
  if (previous === 0) return current === 0 ? undefined : { value: 100, label: 'önceki 7 gün: 0' };
  const pct = Math.round(((current - previous) / previous) * 100);
  return { value: pct, label: `önceki 7 gün: ${previous}` };
}

export function raporCsvOlustur(rows: FraudRaporu[], hedefEtiketleri: Record<string, string>, durumEtiketleri: Record<string, string>): string {
  const header = ['ID', 'Tür', 'Neden', 'Detay', 'Durum', 'Tarih'];
  const lines = rows.map((r) => [
    r.id,
    hedefEtiketleri[r.target_type] ?? r.target_type,
    r.reason ?? '',
    r.details ?? '',
    durumEtiketleri[r.status] ?? r.status,
    new Date(r.created_at).toLocaleString('tr-TR'),
  ].map((v) => `"${String(v).replace(/"/g, '""')}"`).join(','));
  return [header.join(','), ...lines].join('\n');
}
